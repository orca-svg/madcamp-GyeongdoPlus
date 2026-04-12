import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ValidationPipe } from '@nestjs/common';
import { parseCorsOrigins } from './common/utils/cors.util';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    cors: {
      origin: parseCorsOrigins(process.env.CORS_ORIGINS),
      credentials: true,
    },
  });

  // 1. 유효성 검사 (DTO) 전역 적용
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true, // DTO에 없는 속성은 거름
    forbidNonWhitelisted: true, // DTO에 없는 속성이 오면 에러 발생
    transform: true, // 타입 자동 변환
  }));

  // 2. Swagger 설정 (여기 부분이 빠져 있었을 겁니다!)
  const config = new DocumentBuilder()
    .setTitle('경찰과 도둑 (Police & Thief) API')
    .setDescription('실시간 추격전 게임 API 명세서')
    .setVersion('1.0')
    .addBearerAuth() // 나중에 JWT 인증 토큰 넣을 때 필요
    .build();

  if (process.env.SWAGGER_ENABLED !== 'false') {
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api', app, document);
  }

  const host = process.env.HOST || '0.0.0.0';
  const port = parseInt(process.env.PORT || '3000', 10);
  await app.listen(port, host);
}
bootstrap();
