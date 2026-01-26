import { Module } from '@nestjs/common';
import { GameController } from './game.controller';
import { GameService } from './game.service';
import { RedisModule } from '../redis/redis.module'; // 필수!
import { PrismaModule } from '../../database/prisma.module';

@Module({
  imports: [RedisModule, PrismaModule],
  controllers: [GameController],
  providers: [GameService],
})
export class GameModule {}