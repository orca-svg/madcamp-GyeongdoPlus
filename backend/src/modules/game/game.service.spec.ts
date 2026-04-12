import { Test, TestingModule } from '@nestjs/testing';
import { GameService } from './game.service';
import { RedisService } from '../redis/redis.service';
import { PrismaService } from '../../database/prisma.service';
import { EventsGateway } from '../events/events.gateway';

describe('GameService', () => {
  let service: GameService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GameService,
        {
          provide: RedisService,
          useValue: {},
        },
        {
          provide: PrismaService,
          useValue: {},
        },
        {
          provide: EventsGateway,
          useValue: {},
        },
      ],
    }).compile();

    service = module.get<GameService>(GameService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
