import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

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

  const document = SwaggerModule.createDocument(app, config);
  
  // 'api'라는 주소로 Swagger를 띄우겠다는 설정
  SwaggerModule.setup('api', app, document); 

  await app.listen(3000);
}
bootstrap();