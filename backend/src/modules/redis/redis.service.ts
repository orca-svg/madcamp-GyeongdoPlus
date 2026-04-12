import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private redis!: Redis;

  async onModuleInit() {
    this.redis = new Redis({
      host: process.env.REDIS_HOST || 'localhost',
      port: Number.parseInt(process.env.REDIS_PORT || '6379', 10),
      password: process.env.REDIS_PASSWORD || undefined,
    });

    await this.redis.ping();
  }

  async ping() {
    return this.redis.ping();
  }

  async onModuleDestroy() {
    if (this.redis.status === 'ready') {
      await this.redis.quit();
      return;
    }

    this.redis.disconnect();
  }

  // --- 기본 메서드 ---

  async set(key: string, value: string, ttl?: number) {
    if (ttl) {
      return this.redis.set(key, value, 'EX', ttl);
    }
    return this.redis.set(key, value);
  }

  async get(key: string) {
    return this.redis.get(key);
  }

  async del(key: string) {
    return this.redis.del(key);
  }

  // --- Hash 메서드 (방 생성 로직 등에서 필요) ---

  // 1. Hash 저장
  async hset(key: string, data: Record<string, string | number>) {
    return this.redis.hset(key, data);
  }

  // 2. Hash 전체 조회
  async hgetall(key: string) {
    return this.redis.hgetall(key);
  }

  // 3. Hash 특정 필드 삭제
  async hdel(key: string, field: string) {
    return this.redis.hdel(key, field);
  }

  // [추가] 패턴으로 키 목록 조회 (예: game:123:player:*)
  async keys(pattern: string): Promise<string[]> {
    return this.redis.keys(pattern);
  }

  // [추가] GEO: 위치 등록 (경도, 위도, 멤버)
  async geoadd(key: string, lng: number, lat: number, member: string) {
    return this.redis.geoadd(key, lng, lat, member);
  }

  // [추가] GEO: 두 멤버 사이의 거리 계산 (단위: m)
  async geodist(key: string, member1: string, member2: string) {
    const dist = await this.redis.geodist(key, member1, member2);
    return dist ? parseFloat(dist) : null;
  }

  // [추가] LIST: 오른쪽에서 넣기 (Push) - 감옥 대기열
  async rpush(key: string, value: string) {
    return this.redis.rpush(key, value);
  }

  // [추가] LIST: 왼쪽에서 꺼내기 (Pop) - FIFO 구조 (먼저 잡힌 사람 먼저 구출)
  async lpop(key: string) {
    return this.redis.lpop(key);
  }

  async rpop(key: string) {
    return this.redis.rpop(key);
  }

  // [추가] LIST: 리스트 길이 확인
  async llen(key: string) {
    return this.redis.llen(key);
  }

  async hincrby(key: string, field: string, increment: number) {
    return this.redis.hincrby(key, field, increment);
  }

  // [추가] Hash: 단일 필드 조회
  async hget(key: string, field: string) {
    return this.redis.hget(key, field);
  }

  async lrem(key: string, count: number, value: string) {
    return this.redis.lrem(key, count, value);
  }

  // [추가] List: 범위 조회 (감옥 리스트, 아이템 리스트 조회)
  async lrange(key: string, start: number, stop: number) {
    return this.redis.lrange(key, start, stop);
  }

  async exists(key: string) {
    return this.redis.exists(key);
  }

  async geopos(key: string, member: string) {
    return this.redis.geopos(key, member);
  }

  async expire(key: string, seconds: number) {
    return this.redis.expire(key, seconds);
  }

  async zrem(key: string, member: string) {
    return this.redis.zrem(key, member);
  }

  async georadius(
    key: string,
    lng: number,
    lat: number,
    radius: number,
    unit: 'm' | 'km' = 'm',
  ): Promise<[string, string][]> {
    return this.redis.georadius(key, lng, lat, radius, unit, 'WITHDIST', 'ASC') as any;
  }
}
