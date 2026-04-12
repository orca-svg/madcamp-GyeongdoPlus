import { ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from './database/prisma.service';
import { HealthController } from './health.controller';
import { RedisService } from './modules/redis/redis.service';

describe('HealthController', () => {
  it('returns a deployable health payload', () => {
    const controller = new HealthController(
      { isReady: jest.fn() } as unknown as PrismaService,
      { ping: jest.fn() } as unknown as RedisService,
    );
    const payload = controller.getHealth();

    expect(payload.ok).toBe(true);
    expect(payload.service).toBe('gyeongdoplus-backend');
    expect(typeof payload.timestamp).toBe('string');
  });

  it('returns dependency readiness when db and redis are healthy', async () => {
    const controller = new HealthController(
      { isReady: jest.fn().mockResolvedValue(null) } as unknown as PrismaService,
      { ping: jest.fn().mockResolvedValue('PONG') } as unknown as RedisService,
    );

    const payload = await controller.getReady();

    expect(payload.ok).toBe(true);
    expect(payload.dependencies).toEqual({
      database: true,
      redis: true,
    });
  });

  it('throws 503 when a dependency is not ready', async () => {
    const controller = new HealthController(
      { isReady: jest.fn().mockRejectedValue(new Error('db down')) } as unknown as PrismaService,
      { ping: jest.fn().mockResolvedValue('PONG') } as unknown as RedisService,
    );

    await expect(controller.getReady()).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });
});
