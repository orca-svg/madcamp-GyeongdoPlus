// src/modules/lobby/lobby.module.ts
import { Module } from '@nestjs/common';
import { LobbyController } from './lobby.controller';
import { LobbyService } from './lobby.service';
import { PrismaModule } from '../../database/prisma.module';
import { RedisModule } from '../redis/redis.module';

@Module({
  imports: [PrismaModule, RedisModule],
  controllers: [LobbyController],
  providers: [LobbyService],
})
export class LobbyModule {}