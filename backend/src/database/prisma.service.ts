import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
    constructor() {
    super({
      // 쿼리 로그를 콘솔에 찍어줍니다.
      log: ['query', 'info', 'warn', 'error'],
    });
  }
  
  // 1. 모듈이 초기화될 때 DB에 연결합니다.
  async onModuleInit() {
    await this.$connect();
  }

  // 2. 앱이 종료될 때 DB 연결을 깔끔하게 끊습니다. 
  async onModuleDestroy() {
    await this.$disconnect();
  }
}