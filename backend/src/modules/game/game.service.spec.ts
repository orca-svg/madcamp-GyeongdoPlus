import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { GameService } from './game.service';
import { RedisService } from '../redis/redis.service';
import { PrismaService } from '../../database/prisma.service';
import { EventsGateway } from '../events/events.gateway';

describe('GameService', () => {
  let service: GameService;
  let redisService: Record<string, jest.Mock>;

  beforeEach(async () => {
    redisService = {
      hgetall: jest.fn(),
      hget: jest.fn(),
      hset: jest.fn(),
      exists: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GameService,
        { provide: RedisService, useValue: redisService },
        { provide: PrismaService, useValue: {} },
        { provide: EventsGateway, useValue: {} },
      ],
    }).compile();

    service = module.get<GameService>(GameService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('selectAbility', () => {
    it('throws when game is PLAYING and not in PREPARE phase', async () => {
      redisService.hgetall.mockResolvedValue({
        game_status: 'PLAYING',
        phase: 'RUNNING',
      });

      await expect(
        service.selectAbility('user-1', {
          matchId: 'match-1',
          abilityClass: 'SEARCHER',
        }),
      ).rejects.toThrow(BadRequestException);

      expect(redisService.hset).not.toHaveBeenCalled();
    });

    it('allows selection during PREPARE phase even while PLAYING', async () => {
      redisService.hgetall.mockResolvedValue({
        game_status: 'PLAYING',
        phase: 'PREPARE',
      });
      redisService.hget.mockResolvedValue('POLICE');
      redisService.hset.mockResolvedValue(undefined);

      const result = await service.selectAbility('user-1', {
        matchId: 'match-1',
        abilityClass: 'SEARCHER',
      });

      expect(result.success).toBe(true);
    });

    it('allows selection when game status is WAITING', async () => {
      redisService.hgetall.mockResolvedValue({
        game_status: 'WAITING',
        phase: undefined,
      });
      redisService.hget.mockResolvedValue('THIEF');
      redisService.hset.mockResolvedValue(undefined);

      const result = await service.selectAbility('user-1', {
        matchId: 'match-1',
        abilityClass: 'SHADOW',
      });

      expect(result.success).toBe(true);
    });
  });
});
