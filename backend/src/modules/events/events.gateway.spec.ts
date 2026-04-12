import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { EventsGateway } from './events.gateway';
import { RedisService } from '../redis/redis.service';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../database/prisma.service';

describe('EventsGateway', () => {
  let gateway: EventsGateway;
  let redisService: Record<string, jest.Mock>;

  beforeEach(async () => {
    redisService = {
      exists: jest.fn(),
      hset: jest.fn(),
      hgetall: jest.fn(),
      hget: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EventsGateway,
        { provide: RedisService, useValue: redisService },
        { provide: JwtService, useValue: {} },
        { provide: PrismaService, useValue: {} },
      ],
    }).compile();

    gateway = module.get<EventsGateway>(EventsGateway);
    (gateway as any).server = { to: jest.fn().mockReturnValue({ emit: jest.fn() }) };
  });

  function makeClient(userId: string, matchId?: string): any {
    const rooms = new Set<string>(['socket-id-123']);
    if (matchId) rooms.add(matchId);
    return {
      data: { userId },
      rooms,
      handshake: { query: {} },
    };
  }

  describe('handleReadyUpdate', () => {
    it('throws BadRequestException when player is not a member of the match', async () => {
      redisService.exists.mockResolvedValue(0);
      const client = makeClient('attacker', 'victim-match-id');

      await expect(
        (gateway as any).handleReadyUpdate(client, {
          matchId: 'victim-match-id',
          isReady: true,
        }),
      ).rejects.toThrow(BadRequestException);

      expect(redisService.hset).not.toHaveBeenCalled();
    });

    it('allows ready update when player is a legitimate member', async () => {
      redisService.exists.mockResolvedValue(1);
      redisService.hset.mockResolvedValue(undefined);
      const client = makeClient('member-user', 'my-match-id');

      const result = await (gateway as any).handleReadyUpdate(client, {
        matchId: 'my-match-id',
        isReady: true,
      });

      expect(redisService.hset).toHaveBeenCalledWith(
        'game:my-match-id:player:member-user',
        { ready: 'true' },
      );
      expect(result.data.ready).toBe(true);
    });
  });
});
