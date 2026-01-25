import { ConflictException, Injectable, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service'; // 경로 확인 필요
import { LocalSignupDto } from './dto/signup.dto';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { RedisService } from 'src/redis/redis.service'; // Redis 모듈 경로 확인 필요 (혹은 CacheManager)
import { Provider } from '@prisma/client'; // Prisma Enum

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private redisService: RedisService,
  ) {}

  async signup(dto: LocalSignupDto) {
    const { email, password, nickname } = dto;

    // 1. 중복 확인 (이메일 or 닉네임)
    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [{ email }, { nickname }],
      },
    });

    if (existingUser) {
      throw new ConflictException('이미 존재하는 이메일 또는 닉네임입니다.');
    }

    // 2. 비밀번호 해싱
    const hashedPassword = await bcrypt.hash(password, 10);

    // 3. DB 트랜잭션 (User 생성 + UserStat 초기화)
    try {
      const result = await this.prisma.$transaction(async (tx) => {
        // User 생성
        const newUser = await tx.user.create({
          data: {
            email,
            password: hashedPassword,
            nickname,
            provider: Provider.LOCAL, // Enum 사용
          },
        });

        // UserStat 생성 (초기값은 DB Default 따름)
        await tx.userStat.create({
          data: {
            userId: newUser.id,
          },
        });

        return newUser;
      });

      // 4. 토큰 발급
      const payload = { sub: result.id, email: result.email };
      const accessToken = this.jwtService.sign(payload, { expiresIn: '1h' });
      const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });

      // 5. Redis 저장 (Refresh Token) - TTL: 7일 (초 단위)
      const redisKey = `auth:refresh_token:${result.id}`;
      await this.redisService.set(redisKey, refreshToken, 60 * 60 * 24 * 7);

      // 6. 응답 데이터 구성
      return {
        success: true,
        message: '회원가입 성공',
        data: {
          accessToken,
          refreshToken,
          user: {
            id: result.id,
            email: result.email,
            nickname: result.nickname,
            profileImage: result.profileImage,
          },
        },
      };

    } catch (error) {
        // 중복 에러가 아닌 다른 에러 처리
        if (error instanceof ConflictException) throw error;
        throw new InternalServerErrorException('회원가입 중 오류가 발생했습니다.');
    }
  }
}