// src/database/prisma.module.ts
import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global() // 이렇게 하면 다른 모듈에서 imports 없이 PrismaService를 바로 쓸 수 있음!
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}    