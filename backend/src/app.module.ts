import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './modules/auth/auth.module';
import { RedisModule } from './modules/redis/redis.module';
import { PrismaModule } from './database/prisma.module'; // (*중요: 아래 설명 확인)
import { UserModule } from './modules/user/user.module';
import { LobbyModule } from './modules/lobby/lobby.module';
import { GameModule } from './modules/game/game.module';
import { EventsModule } from './modules/events/events.module';

@Module({
  imports: [
    // 1. 환경변수 설정 (제일 중요)
    ConfigModule.forRoot({
      isGlobal: true, // 어디서든 ConfigService를 쓸 수 있게 함
      envFilePath: '.env', // .env 파일 경로 지정
    }),

    // 2. 공통 모듈 (DB, Redis)
    PrismaModule, // 데이터베이스 모듈
    RedisModule,  // Redis 모듈 (우리가 만든 것)

    // 3. 비즈니스 로직 모듈
    AuthModule, UserModule, LobbyModule, GameModule, EventsModule  // 회원가입, 로그인
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}