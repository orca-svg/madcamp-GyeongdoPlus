import {
  Injectable,
  UnauthorizedException,
  InternalServerErrorException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { JwtService } from '@nestjs/jwt';
import { RedisService } from '../redis/redis.service';
import * as bcrypt from 'bcrypt';
import { 
  LocalSignupDto, 
  LocalLoginDto,
  KakaoLoginDto,
  RefreshRequestDto 
} from './auth.dto';
import { Provider } from '@prisma/client';
import axios from 'axios';
import { v4 as uuidv4 } from 'uuid'; // UUID 생성을 위해 필요할 수 있음 (또는 crypto 사용)

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private redisService: RedisService,
  ) {}

  // ... (기존 signup 메서드 유지) ...
  async signup(dto: LocalSignupDto) {
    // (이전 코드 유지)
    const { email, password, nickname } = dto;
    const existingUser = await this.prisma.user.findFirst({
        where: { OR: [{ email }, { nickname }] },
    });
    if (existingUser) throw new ConflictException('이미 존재하는 이메일 또는 닉네임입니다.');
    
    const hashedPassword = await bcrypt.hash(password, 10);

    return this.prisma.$transaction(async (tx) => {
        const newUser = await tx.user.create({
            data: { email, password: hashedPassword, nickname, provider: Provider.LOCAL },
        });
        await tx.userStat.create({ data: { userId: newUser.id } });
        
        return this.generateAuthResponse(newUser);
    });
  }

  // ----------------------------------------------------------------
  // 1. 로컬 로그인
  // ----------------------------------------------------------------
  async login(dto: LocalLoginDto) {
    const { email, password } = dto;

    // 사용자 조회
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || !user.password) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 잘못되었습니다.');
    }

    // 비밀번호 검증
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 잘못되었습니다.');
    }

    return this.generateAuthResponse(user);
  }

  // ----------------------------------------------------------------
  // 2. 카카오 로그인
  // ----------------------------------------------------------------
  async kakaoLogin(dto: KakaoLoginDto) {
    let kakaoUserInfo;
    try {
      // 카카오 API로 토큰 유효성 검증 및 사용자 정보 가져오기
      const response = await axios.get('https://kapi.kakao.com/v2/user/me', {
        headers: { Authorization: `Bearer ${dto.kakaoAccessToken}` },
      });
      kakaoUserInfo = response.data;
    } catch (error) {
      console.log('🚨 카카오 에러 상세:', error.response?.data || error.message);
      throw new UnauthorizedException('유효하지 않은 카카오 토큰입니다.');
    }

    const email = kakaoUserInfo.kakao_account?.email;
    const socialId = kakaoUserInfo.id.toString(); // 카카오 고유 ID

    if (!email) {
      throw new UnauthorizedException('카카오 계정에 이메일 정보가 없습니다.');
    }

    // DB에서 사용자 찾기
    let user = await this.prisma.user.findUnique({ where: { email } });
    let isNewUser = false;

    // 신규 유저라면 회원가입 진행 (Transaction)
    if (!user) {
      isNewUser = true;
      try {
        user = await this.prisma.$transaction(async (tx) => {
          // 랜덤 닉네임 생성 (예: Guest_xh5a...)
          const randomNickname = `Guest_${uuidv4().substring(0, 8)}`;
          
          const newUser = await tx.user.create({
            data: {
              email,
              nickname: randomNickname,
              provider: Provider.KAKAO,
              socialId: socialId,
              // password는 null
            },
          });

          await tx.userStat.create({ data: { userId: newUser.id } });
          return newUser;
        });
      } catch (error) {
        throw new InternalServerErrorException('카카오 로그인 처리 중 오류 발생');
      }
    }

    const authResponse = await this.generateAuthResponse(user);
    return { ...authResponse, isNewUser };
  }

  // ----------------------------------------------------------------
  // 공통 메서드: 토큰 발급 및 Redis 저장
  // ----------------------------------------------------------------
  private async generateAuthResponse(user: any) {
    const payload = { sub: user.id, email: user.email };
    
    const accessToken = this.jwtService.sign(payload, { expiresIn: '30m' }); // 30분
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' }); // 7일

    // Redis 저장 (TTL: 7일 = 604800초)
    await this.redisService.set(
      `auth:refresh_token:${user.id}`,
      refreshToken,
      604800,
    );

    return {
      success: true,
      message: '로그인 성공',
      data: {
        accessToken,
        refreshToken,
        expiresIn: 1800, // 클라이언트 편의용
        user: {
            id: user.id,
            email: user.email,
            nickname: user.nickname,
            profileImage: user.profileImage
        }
      },
    };
  }

  // ----------------------------------------------------------------
  // 3. 토큰 재발급 (Refresh)
  // ----------------------------------------------------------------
  async refresh(dto: RefreshRequestDto) {
    const { refreshToken } = dto;

    try {
      // 1. 토큰 자체의 유효성 검증 (만료 여부, 서명 확인)
      const payload = this.jwtService.verify(refreshToken, {
        secret: process.env.JWT_SECRET,
      });
      const userId = payload.sub;

      // 2. Redis에 저장된 토큰과 일치하는지 확인 (보안)
      const storedToken = await this.redisService.get(`auth:refresh_token:${userId}`);
      if (storedToken !== refreshToken) {
        throw new UnauthorizedException('유효하지 않거나 만료된 리프레시 토큰입니다. (Redis 불일치)');
      }

      // 3. 유저 정보 조회 (Payload 생성을 위해)
      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (!user) throw new UnauthorizedException('존재하지 않는 사용자입니다.');

      // 4. 토큰 재발급 및 Redis 갱신 (RTR: Refresh Token Rotation)
      // generateAuthResponse 내부에서 Redis 갱신까지 다 해줍니다.
      const newAuthData = await this.generateAuthResponse(user);

      return {
        success: true,
        message: '토큰 재발급 성공',
        data: {
          accessToken: newAuthData.data.accessToken,
          refreshToken: newAuthData.data.refreshToken,
        },
      };

    } catch (e) {
      throw new UnauthorizedException('유효하지 않거나 만료된 리프레시 토큰입니다. 다시 로그인해주세요.');
    }
  }

  // ----------------------------------------------------------------
  // 4. 로그아웃 (Logout)
  // ----------------------------------------------------------------
  async logout(userId: string) {
    // Redis에서 해당 유저의 Refresh Token 삭제 -> 갱신 불가능하게 만듦
    await this.redisService.del(`auth:refresh_token:${userId}`);
    return { success: true, message: '로그아웃 성공' };
  }

  // ----------------------------------------------------------------
  // 5. 닉네임 중복 확인 (Check Nickname)
  // ----------------------------------------------------------------
  async checkNickname(nickname: string) {
    const count = await this.prisma.user.count({
      where: { nickname },
    });

    return {
      success: true,
      message: '확인 완료',
      data: {
        isAvailable: count === 0, // 0명이면 사용 가능(true)
      },
    };
  }
}