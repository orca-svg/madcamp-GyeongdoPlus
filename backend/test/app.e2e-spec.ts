import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { HealthController } from './../src/health.controller';
import { PrismaService } from '../src/database/prisma.service';
import { RedisService } from '../src/modules/redis/redis.service';

describe('HealthController (e2e)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        {
          provide: PrismaService,
          useValue: { isReady: jest.fn().mockResolvedValue(null) },
        },
        {
          provide: RedisService,
          useValue: { ping: jest.fn().mockResolvedValue('PONG') },
        },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('resolves the health controller through the Nest container', () => {
    const controller = app.get(HealthController);
    const body = controller.getHealth();

    expect(body.ok).toBe(true);
    expect(body.service).toBe('gyeongdoplus-backend');
    expect(typeof body.timestamp).toBe('string');
  });

  it('resolves dependency readiness through the Nest container', async () => {
    const controller = app.get(HealthController);
    const body = await controller.getReady();

    expect(body.ok).toBe(true);
    expect(body.dependencies).toEqual({
      database: true,
      redis: true,
    });
  });
});
