import {
  Injectable,
  UnauthorizedException,
  InternalServerErrorException,
  HttpException, // ✅ 커스텀 에러 응답을 위해 추가
  HttpStatus,    // ✅ 상태 코드 사용을 위해 추가
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
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private redisService: RedisService,
  ) { }

  // ----------------------------------------------------------------
  // 1. 회원가입 (Signup)
  // ----------------------------------------------------------------
  async signup(dto: LocalSignupDto) {
    const { email, password, nickname } = dto;

    // 이메일 또는 닉네임 중복 확인
    const existingUser = await this.prisma.user.findFirst({
      where: { OR: [{ email }, { nickname }] },
    });

    // 🚨 [수정] 사진의 409 Conflict 에러 구조와 일치시킴
    if (existingUser) {
      throw new HttpException(
        {
          success: false,
          error: {
            code: 'CONFLICT',
            message: '이미 존재하는 이메일 또는 닉네임입니다.',
          },
        },
        HttpStatus.CONFLICT,
      );
    }

    // 비밀번호 해싱
    const hashedPassword = await bcrypt.hash(password, 10);

    // 트랜잭션으로 유저 및 스탯 생성
    return this.prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: { email, password: hashedPassword, nickname, provider: Provider.LOCAL },
      });
      await tx.userStat.create({ data: { userId: newUser.id } });

      // ✅ [수정] 메시지를 '회원가입 성공'으로 지정
      return this.generateAuthResponse(newUser, '회원가입 성공');
    });
  }

  // ----------------------------------------------------------------
  // 2. 로컬 로그인
  // ----------------------------------------------------------------
  async login(dto: LocalLoginDto) {
    const { email, password } = dto;

    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || !user.password) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 잘못되었습니다.');
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('이메일 또는 비밀번호가 잘못되었습니다.');
    }

    // 메시지 생략 시 기본값 '로그인 성공' 사용
    return this.generateAuthResponse(user, '로그인 성공');
  }

  // ----------------------------------------------------------------
  // 3. 카카오 로그인
  // ----------------------------------------------------------------
  async kakaoLogin(dto: KakaoLoginDto) {
    let kakaoUserInfo;
    try {
      const response = await axios.get('https://kapi.kakao.com/v2/user/me', {
        headers: { Authorization: `Bearer ${dto.kakaoAccessToken}` },
      });
      kakaoUserInfo = response.data;
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: '유효하지 않은 카카오 토큰입니다.',
          data: null,
          error: {
            code: 'INVALID_KAKAO_TOKEN',
          },
        },
        HttpStatus.UNAUTHORIZED,
      );
    }

    const email = kakaoUserInfo.kakao_account?.email;
    const socialId = kakaoUserInfo.id.toString();

    if (!email) {
      throw new UnauthorizedException('카카오 계정에 이메일 정보가 없습니다.');
    }

    let user = await this.prisma.user.findUnique({ where: { email } });
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      try {
        user = await this.prisma.$transaction(async (tx) => {
          const randomNickname = `Guest_${uuidv4().substring(0, 8)}`;
          const newUser = await tx.user.create({
            data: {
              email,
              nickname: randomNickname,
              provider: Provider.KAKAO,
              socialId: socialId,
            },
          });
          await tx.userStat.create({ data: { userId: newUser.id } });
          return newUser;
        });
      } catch (error) {
        throw new InternalServerErrorException('카카오 로그인 처리 중 오류 발생');
      }
    }

    // 카카오 로그인은 별도 메시지 처리가 없다면 기본값 사용, 혹은 커스텀 가능
    const authResponse = await this.generateAuthResponse(user, '로그인 성공');
    return { ...authResponse, isNewUser };
  }

  // ----------------------------------------------------------------
  // 🛠️ 공통 메서드: 토큰 발급 및 응답 생성 (핵심 수정 부분)
  // ----------------------------------------------------------------
  private async generateAuthResponse(user: any, message: string = '로그인 성공') {
    const payload = { sub: user.id, email: user.email };

    const accessToken = this.jwtService.sign(payload, { expiresIn: '30m' });
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });

    await this.redisService.set(
      `auth:refresh_token:${user.id}`,
      refreshToken,
      604800,
    );

    return {
      success: true,
      message: message, // ✅ 상황에 맞는 메시지 전달 ('회원가입 성공' 등)
      data: {
        accessToken,
        refreshToken,
        expiresIn: 1800,
        user: {
          id: user.id,
          email: user.email,
          nickname: user.nickname,
          profileImage: user.profileImage
        }
      },
      error: null, // ✅ [수정] 사진 명세와 일치하도록 null 필드 추가
    };
  }

  // ----------------------------------------------------------------
  // 4. 토큰 재발급 (Refresh)
  // ----------------------------------------------------------------
  async refresh(dto: RefreshRequestDto) {
    const { refreshToken } = dto;

    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: process.env.JWT_SECRET,
      });
      const userId = payload.sub;

      const storedToken = await this.redisService.get(`auth:refresh_token:${userId}`);
      if (storedToken !== refreshToken) {
        throw new UnauthorizedException('유효하지 않거나 만료된 리프레시 토큰입니다. (Redis 불일치)');
      }

      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (!user) throw new UnauthorizedException('존재하지 않는 사용자입니다.');

      const newAuthData = await this.generateAuthResponse(user, '토큰 재발급 성공');

      return {
        success: true,
        message: '토큰 재발급 성공',
        data: {
          accessToken: newAuthData.data.accessToken,
          refreshToken: newAuthData.data.refreshToken,
        },
        error: null // 여기도 통일감 있게 추가
      };

    } catch (e) {
      throw new HttpException(
        {
          success: false,
          error: {
            code: 'UNAUTHORIZED',
            message: '유효하지 않거나 만료된 리프레시 토큰입니다. 다시 로그인해주세요.',
          },
        },
        HttpStatus.UNAUTHORIZED,
      );
    }
  }

  // ----------------------------------------------------------------
  // 5. 로그아웃 (Logout) - Blacklist 기능 추가
  // ----------------------------------------------------------------
  // 🚨 [수정] Access Token을 인자로 받아야 블랙리스트 등록 가능
  async logout(userId: string, accessToken: string) {
    // 1. Refresh Token 삭제 (기존 로직)
    await this.redisService.del(`auth:refresh_token:${userId}`);

    // 2. Access Token 블랙리스트 등록 (추가된 로직)
    // Access Token의 남은 유효시간을 계산하거나, 단순히 표준 만료시간(30분)으로 설정
    // 키: auth:blacklist:{token}, 값: 'true', TTL: 1800초 (30분)
    if (accessToken) {
      // "Bearer " 접두사가 있다면 제거
      const token = accessToken.replace('Bearer ', '');
      await this.redisService.set(`auth:blacklist:${token}`, 'true', 1800);
    }

    return { success: true, message: '로그아웃 성공', error: null };
  }

  // ----------------------------------------------------------------
  // 6. 닉네임 중복 확인 (Check Nickname)
  // ----------------------------------------------------------------
  async checkNickname(nickname: string) {
    const count = await this.prisma.user.count({
      where: { nickname },
    });

    return {
      success: true,
      message: '확인 완료',
      data: {
        isAvailable: count === 0,
      },
      error: null
    };
  }
}