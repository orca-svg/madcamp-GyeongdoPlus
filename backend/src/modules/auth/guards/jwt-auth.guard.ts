// src/modules/auth/guards/jwt-auth.guard.ts

import {
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { RedisService } from '../../redis/redis.service';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private readonly redisService: RedisService) {
    super();
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // 1. Passport의 기본 JWT 검증 로직 실행
    const canActivate = await super.canActivate(context);
    if (!canActivate) return false;

    const request = context.switchToHttp().getRequest();
    const token = request.headers.authorization?.split(' ')[1];

    if (token) {
      // 2. Redis 블랙리스트 확인 (로그아웃된 토큰인지 체크)
      const isBlacklisted = await this.redisService.get(`auth:blacklist:${token}`);
      if (isBlacklisted) {
        throw new UnauthorizedException('로그아웃된 토큰입니다. 다시 로그인해주세요.');
      }
    }

    return true;
  }
}