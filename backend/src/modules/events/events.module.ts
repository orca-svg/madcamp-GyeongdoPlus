// src/modules/events/events.module.ts
import { Module, Global } from '@nestjs/common';
import { EventsGateway } from './events.gateway';
import { JwtModule } from '@nestjs/jwt'; // JWT 검증용
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../../database/prisma.module';
import { RedisModule } from '../redis/redis.module';

@Global() // ⭐ 중요: 전역 모듈로 만들면 GameModule에서 imports 없이도 쓸 수 있음 (선택사항)
@Module({
  imports: [ConfigModule, JwtModule.register({}), PrismaModule, RedisModule],
  providers: [EventsGateway],
  exports: [EventsGateway], // ⭐ GameService에서 쓰기 위해 내보내기 필수
})
export class EventsModule {}
