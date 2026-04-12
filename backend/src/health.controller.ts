import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from './database/prisma.service';
import { RedisService } from './modules/redis/redis.service';

@Controller()
export class HealthController {
  constructor(
    private readonly prismaService: PrismaService,
    private readonly redisService: RedisService,
  ) {}

  @Get('health')
  getHealth() {
    return {
      ok: true,
      service: 'gyeongdoplus-backend',
      timestamp: new Date().toISOString(),
    };
  }

  @Get('ready')
  async getReady() {
    const checks = {
      database: false,
      redis: false,
    };

    try {
      await this.prismaService.isReady();
      checks.database = true;
    } catch (_) {}

    try {
      await this.redisService.ping();
      checks.redis = true;
    } catch (_) {}

    const payload = {
      ok: checks.database && checks.redis,
      service: 'gyeongdoplus-backend',
      dependencies: checks,
      timestamp: new Date().toISOString(),
    };

    if (!payload.ok) {
      throw new ServiceUnavailableException(payload);
    }

    return payload;
  }

  @Get('health/ready')
  async getLegacyReady() {
    return this.getReady();
  }
}
