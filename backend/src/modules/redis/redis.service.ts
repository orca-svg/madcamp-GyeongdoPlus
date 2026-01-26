import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private client: Redis;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    this.client = new Redis({
      host: this.configService.get<string>('REDIS_HOST'),
      port: this.configService.get<number>('REDIS_PORT'),
      password: this.configService.get<string>('REDIS_PASSWORD'),
    });
  }

  onModuleDestroy() {
    this.client.quit();
  }

  // 1. 기본 저장 (Key, Value, TTL-초 단위)
  async set(key: string, value: string, ttl?: number): Promise<void> {
    if (ttl) {
      await this.client.set(key, value, 'EX', ttl);
    } else {
      await this.client.set(key, value);
    }
  }

  // 2. 조회
  async get(key: string): Promise<string | null> {
    return this.client.get(key);
  }

  // 3. 삭제
  async del(key: string): Promise<void> {
    await this.client.del(key);
  }

  // 4. (게임용) Redis 클라이언트 직접 접근 - GEO, HASH 명령어 등 사용 시 필요
  getClient(): Redis {
    return this.client;
  }
}