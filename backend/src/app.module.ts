import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './modules/auth/auth.module';
import { RedisModule } from './modules/redis/redis.module';
import { PrismaModule } from './database/prisma.module'; // (*중요: 아래 설명 확인)

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
    AuthModule,   // 회원가입, 로그인
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}