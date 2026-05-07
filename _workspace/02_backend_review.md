# Backend 코드리뷰 결과

## 요약
- 총 발견 이슈: 24개 (CRITICAL: 9, WARNING: 9, SUGGESTION: 6)
- 리뷰 대상: NestJS 백엔드 (events.gateway / game.service / lobby.service / auth / main / redis)
- 핵심 결론: WS 인증/예외 처리가 미흡하고 Redis 상에서 비원자적 read-modify-write·KEYS 패턴이 다수라 동시성/메모리 위험. 게임 종료 후 키 정리도 expire 1시간만 적용하여 좀비 데이터 잔존. JWT 시크릿이 ConfigService 대신 process.env로 분산 참조되고, WS 핸드셰이크에서 토큰 블랙리스트 검증이 누락되어 있음.

---

## CRITICAL 이슈

### C1. backend/src/modules/events/events.gateway.ts:99-108 — `join_room` 핸들러 권한/멤버십 검증 부재
`handleJoinRoom`은 클라이언트가 보낸 `matchId`만 받아 무조건 `socket.join` 한다. Redis `game:{matchId}:player:{userId}` 멤버십 체크가 없어 임의의 사용자가 남의 매치 룸에 들어와 모든 브로드캐스트(이동 위치, 체포 등)를 도청 가능. `handleConnection`(line 75-84)도 `query.matchId`만 보고 즉시 join 한다 — 동일 문제.

현재 코드:
```typescript
@SubscribeMessage('join_room')
handleJoinRoom(@ConnectedSocket() client, @MessageBody() data: { matchId: string }) {
  client.join(data.matchId);  // ❌ 멤버십 검증 없음
  return { event: 'joined_room', data: { matchId: data.matchId } };
}
```

개선안:
```typescript
@SubscribeMessage('join_room')
async handleJoinRoom(@ConnectedSocket() client, @MessageBody() data: { matchId: string }) {
  const userId = client.data.userId?.toString();
  if (!userId) throw new UnauthorizedException();
  const ok = await this.redisService.exists(`game:${data.matchId}:player:${userId}`);
  if (!ok) throw new ForbiddenException('해당 매치 참가자가 아닙니다.');
  await client.join(data.matchId);
  return { event: 'joined_room', data: { matchId: data.matchId } };
}
```
handleConnection에서도 query.matchId 자동 join 전에 동일 검증을 적용해야 한다.

### C2. backend/src/modules/events/events.gateway.ts:53-91, 110-218 — WS 핸들러에서 던진 예외가 클라이언트로 표준화되어 전달되지 않음
gateway 핸들러 다수가 `BadRequestException`/`ForbiddenException`을 그대로 throw 한다. NestJS WebSocket은 HTTP 예외 필터를 자동 적용하지 않으므로, 글로벌 `WsExceptionFilter`가 없으면 클라이언트는 ack 콜백에서 일관된 에러를 못 받고 서버 로그에만 unhandled rejection이 남는다.

현재 코드:
```typescript
@SubscribeMessage('update_settings')
async handleUpdateSettings(...) {
  if (globalState.host_id !== requesterId) {
    throw new ForbiddenException('방장만 설정을 변경할 수 있습니다.'); // ❌ ack로 전달 안 됨
  }
}
```

개선안: 전역 WsExceptionFilter 적용.
```typescript
@Catch()
export class WsAllExceptionsFilter extends BaseWsExceptionFilter {
  catch(exception: any, host: ArgumentsHost) {
    const client = host.switchToWs().getClient<Socket>();
    const status = exception?.status ?? 500;
    const payload = {
      success: false,
      message: exception?.message ?? 'error',
      code: exception?.response?.error?.code ?? status,
    };
    client.emit('error', payload);
  }
}
// app.useGlobalFilters(new WsAllExceptionsFilter());
```
또한 `client.disconnect()` 직전에 `auth_error` 이벤트를 emit해 클라이언트가 재로그인을 트리거하도록 해야 한다.

### C3. backend/src/modules/events/events.gateway.ts:182-198 — Prisma 업데이트 + Redis 업데이트 분리로 인한 데이터 불일치
`update_settings`에서 Prisma update 성공 후 Redis hset가 실패해도 보상 트랜잭션이 없다. Prisma는 변경됨인데 Redis는 옛 값 → 게임 로직(Redis 기반)은 변경 전 상태로 동작.

현재 코드:
```typescript
const updatedMatch = await this.prismaService.gameMatch.update({...});
// ❌ Redis hset 실패 시 rollback 불가
if (Object.keys(redisUpdateData).length > 0) {
  await this.redisService.hset(`game:${matchId}:state`, redisUpdateData);
}
```

개선안: (a) Redis를 source-of-truth로 정하고 DB는 종료 시 flush, (b) outbox 패턴, (c) 최소한 try/catch로 Redis 실패 시 Prisma 변경을 보상 update.

### C4. backend/src/modules/game/game.service.ts:519-555, 681-697 — `updatePosition` 게이지/심박수 read-modify-write 비원자성
같은 시점에 여러 위치 갱신 요청(WS 재시도, 워치+폰 동시), `processAutoArrest`/`CLOWN` 패시브가 같은 hash 필드 동시 수정. `hgetall` → 계산 → `hset` 사이에 끼어들면 `ability_gauge`, `last_gauge_update`, `max_heart_rate`가 덮어써진다. CLOWN의 `+2` 충전(681-697)도 별도 hget→parse→hset이라 누적 손실 가능.

현재 코드:
```typescript
const currentGauge = parseFloat(playerState.ability_gauge || '0');
const addedGauge = increaseRate * deltaSec;
const newGauge = Math.min(currentGauge + addedGauge, 100);
await this.redisService.hset(playerKey, { ability_gauge: newGauge, last_gauge_update: now });
// ❌ 두 요청 동시 시 손실
```

개선안: HINCRBYFLOAT 또는 Lua script로 cap 포함 원자적 처리.
```lua
-- ability_gauge_charge.lua
local cur = tonumber(redis.call('HGET', KEYS[1], 'ability_gauge')) or 0
local add = tonumber(ARGV[1]) or 0
local cap = tonumber(ARGV[2]) or 100
local nv  = math.min(cur + add, cap)
redis.call('HSET', KEYS[1], 'ability_gauge', nv, 'last_gauge_update', ARGV[3])
return nv
```

### C5. backend/src/modules/game/game.service.ts:299-306, 384-392 — `useItem` 팀 1회 제한 NX 부재로 더블 사용 가능
`AREA_SIREN`, `REMOTE_RESCUE`의 “팀 1회 제한” NX 대체 로직이 `get` 후 `set`이라 두 명이 동시에 검사하면 둘 다 통과한다.

현재 코드:
```typescript
const sirenKey = `game:${matchId}:team_limit:siren`;
if (await this.redisService.get(sirenKey)) { ... throw ... }
await this.redisService.set(sirenKey, 'used', 3600); // ❌ get-then-set: race
```

개선안: `SET NX EX`. RedisService에 `setNx` 추가.
```typescript
async setNx(key: string, value: string, ttl: number) {
  return this.redis.set(key, value, 'EX', ttl, 'NX');
}
// 사용
const acquired = await this.redisService.setNx(sirenKey, 'used', 3600);
if (!acquired) {
  await this.redisService.rpush(itemsKey, itemId);  // 보상
  throw new BadRequestException('이미 팀에서 광역 사이렌을 사용했습니다.');
}
```
또한 `useItem`의 일부 분기(예: EMP 활성 시 throw)에서 `lrem`된 아이템에 대한 보상 `rpush`가 누락된 경로가 있는지 점검 필요.

### C6. backend/src/modules/game/game.service.ts:1127-1131 — 게임 종료 후 Redis 키 정리가 expire 1시간만 적용
`endGame`에서 `keys('game:{matchId}:*')`로 모든 키에 EXPIRE 3600을 거는데:
1. 즉시 삭제가 아니어서 같은 matchId로 들어오는 잔여 메시지(이동 등)가 1시간 동안 좀비 상태.
2. `keys` 커맨드 자체가 운영 환경에서 블로킹 (C7 참조).
3. EXPIRE는 zset 내부 멤버 단위가 아니라 키 단위라, decoy GEO member 등은 키가 만료될 때까지 그대로.

현재 코드:
```typescript
const allKeys = await this.redisService.keys(`game:${matchId}:*`);
for (const key of allKeys) {
  await this.redisService.expire(key, 3600);  // ❌ N round-trip
}
```

개선안:
- 즉시 정리 키와 보존 키 구분: 게임 진행용(geo, prison_queue, player:*:items, decoy:*, team_limit:*)은 `del`, 통계용은 expire.
- `keys` 대신 `SCAN` + pipeline 사용.
- 매치 동시 종료 부하 분산을 위해 BullMQ로 비동기 큐잉.

### C7. backend/src/modules/lobby/lobby.service.ts:106, 177, 200, 241, 425; game.service.ts:1039, 1128, 1315 — `KEYS` 명령어 남용 (운영 블로킹)
입장/시작/종료/leave 등 핫 경로에서 `redisService.keys('game:{matchId}:player:*')` 호출. Redis는 single-thread이므로 KEYS는 데이터셋 전체 스캔이며 100만 키 환경에서 수백 ms 정지 발생 → 모든 매치 정지.

현재 코드:
```typescript
const playerKeys = await this.redisService.keys(`game:${matchId}:player:*`);
```

개선안: 매치별 player SET 별도 유지.
```typescript
// join 시
await this.redisService.sadd(`game:${matchId}:players`, userId);
// 조회 시
const ids = await this.redisService.smembers(`game:${matchId}:players`);
// 그 후 pipeline으로 hgetall 병렬 조회
```
불가피하면 `SCAN` (cursor + MATCH + COUNT)으로 교체.

### C8. backend/src/modules/game/game.service.ts:1297-1407 — `leaveGame` 호스트 자동 위임 버그 + race
- (a) line 1322: `playerKeys.filter(key => !key.includes('items') && !key.endsWith(userId))`에서 `endsWith`는 다른 사용자 id 끝이 leaver와 같을 때 잘못 필터링됨 (예: leaver=`1234`, 다른 유저=`x1234`).
- (b) DB update와 Redis hset 사이에 동시 leaveGame 실행되면 두 명이 동시에 새 호스트가 될 수 있음.
- (c) 후보 없을 때 “방 폭파” 처리 누락 → 좀비 매치 잔존.

현재 코드:
```typescript
playerKeys
  .filter(key => !key.includes('items') && !key.endsWith(userId))  // ❌ endsWith 오탐
```

개선안:
```typescript
const myKey = `game:${matchId}:player:${userId}`;
const candidates = playerKeys
  .filter(k => k.split(':').length === 4 && k !== myKey);
// 호스트 위임은 SET NX 락
const acquired = await this.redisService.setNx(`lock:host:${matchId}`, userId, 5);
if (!acquired) throw new ConflictException('진행 중인 위임이 있습니다.');
// ... DB+Redis 업데이트 ...
await this.redisService.del(`lock:host:${matchId}`);
```

### C9. backend/src/modules/events/events.gateway.ts:66-68; auth.service.ts:191; jwt.strategy.ts:15 — JWT 시크릿 다중 출처 + WS handshake 블랙리스트 미검증
- `JwtModule`은 `ConfigService.get('JWT_SECRET')`로, `EventsGateway`는 `process.env.JWT_SECRET`로, `AuthService.refresh`도 `process.env.JWT_SECRET`로 검증한다. ConfigModule이 .env load 전 import 되면 verify가 silent fail.
- 더 큰 문제: `EventsGateway.handleConnection`은 토큰 검증만 하고 **Redis 블랙리스트(`auth:blacklist:{token}`) 체크 없음**. HTTP는 `JwtAuthGuard`가 막지만 WS는 로그아웃된 토큰으로도 게임 룸 잔류.

현재 코드:
```typescript
const payload = this.jwtService.verify(token, { secret: process.env.JWT_SECRET });
// ❌ blacklist 미체크
client.data.userId = payload.sub;
```

개선안:
```typescript
const payload = this.jwtService.verify(token, { secret: this.configService.get('JWT_SECRET') });
const isBlack = await this.redisService.get(`auth:blacklist:${token}`);
if (isBlack) throw new UnauthorizedException('로그아웃된 토큰입니다.');
// 단일 디바이스 정책이라면 user별 활성 socketId를 Redis에 저장하고 중복 접속 거부.
```

---

## WARNING 이슈

### W1. backend/src/modules/game/game.service.ts:716-739 — `updatePosition` nearby 스캔 N+1
50m 반경 각 타깃마다 `hgetall` + `get`(stealth)를 두 번씩 호출. 인원 N이면 매 move마다 2N round-trip.

개선안: ioredis pipeline.
```typescript
const pipe = this.redis.pipeline();
nearbyRaw.forEach(([id]) => {
  pipe.hgetall(`game:${matchId}:player:${id}`);
  pipe.get(`game:${matchId}:player:${id}:stealth_active`);
});
const results = await pipe.exec();
```

### W2. backend/src/modules/game/game.service.ts:1051-1102 — `endGame` 플레이어 hgetall N+1 (Prisma transaction 전)
플레이어마다 sequential hgetall. Prisma `$transaction` 안에서 timing이 길어지면 connection pool 고갈.

### W3. backend/src/modules/auth/auth.service.ts:153-181 — accessToken/refreshToken 동일 secret
access(30m)와 refresh(7d)를 같은 비밀로 서명. access 누출 시 refresh 위조 가능. `JWT_REFRESH_SECRET` 분리 필요.

### W4. backend/src/main.ts; redis.service.ts:9-13; jwt.strategy.ts:15; events.gateway.ts:67 — 환경변수 직접 접근
`process.env.JWT_SECRET`, `process.env.REDIS_HOST`, `process.env.PORT`가 코드 곳곳. ConfigModule + joi schema 검증 도입 권장. 누락 시 부팅 실패하도록 강제.

### W5. backend/src/common/utils/room-code.util.ts:14-18 — `Math.random` 4자리 코드 (충돌·예측)
- 4글자 36진수 = 36^4 = 1.68M. 동시 매치 수백 개일 때 collision 확률 상승.
- `Math.random`은 비암호학적 → 시드 추정 가능.
- `lobby.service.ts:29`의 while 루프는 DB unique 검사만 하고, redis `room:{code}` 매핑은 setNx가 아님 → 동시 race 가능.

개선안:
```typescript
import { randomInt } from 'crypto';
export function generateRoomCode(len = 5): string {
  const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'; // 0/O/1/I 제거 + 길이↑
  let out = '';
  for (let i = 0; i < len; i++) out += chars[randomInt(chars.length)];
  return out;
}
// + redis SET NX 로 reservation 후 DB insert
```

### W6. backend/src/modules/lobby/lobby.service.ts:79-151 — `joinRoom` 정원 초과 race
정원 체크(`playerKeys.length >= max_players`) 후 `hset` 사이에 두 명이 동시에 들어오면 capacity+1 가능. 또 같은 사용자가 여러 번 join 시 player hash가 덮어써져 `joined_at` 갱신.

개선안: Lua script로 atomic 정원 검사 + 추가.
```lua
-- joinRoom.lua
local cur = redis.call('SCARD', KEYS[1])
if cur >= tonumber(ARGV[1]) then return -1 end
redis.call('SADD', KEYS[1], ARGV[2])
return cur + 1
```

### W7. backend/src/modules/events/events.gateway.ts:265-300 — `change_role` 모든 참가자 무제한 호출 + 팀 밸런스 실시간 검증 부재
`game_status === 'WAITING'`만 검사. 모든 참가자가 자유롭게 role 변경 가능. startGame은 검증하지만 PREP 시작 직전 race 발생 시 일시적 팀 불균형. 또한 `class: ''`로 초기화한 뒤 클라이언트가 재선택 안 하면 `useAbility`가 막히는데 별도 알림 emit이 없음.

### W8. backend/src/modules/lobby/lobby.dto.ts:32, 43 — `mapConfig`, `rules`가 `any` (nested validation 없음)
`@IsObject()`만 있고 nested validation 없음. polygon 좌표·jail.lat/lng 등 게임 핵심 데이터가 임의 형태로 통과. 코드 곳곳에 `as any` 캐스팅 산재.

개선안: `MapConfigDto`/`RulesDto` class 정의 후 `@ValidateNested() @Type(() => MapConfigDto)`.

### W9. backend/src/modules/game/game.service.ts:1593-1648 — integrity violation마다 prisma round-trip
`registerIntegrityViolation`이 `userStat.findUnique` + `upsert` 동기 호출. 위치 update 핫 경로에서 매번 발생 가능. 또한 emit→DB쓰기 사이 또 다른 위반이 들어오면 integrityScore가 잘못 깎임. BullMQ queue로 비동기화 권장.

---

## SUGGESTION

### S1. backend/src/modules/events/events.gateway.ts:101-108 — WS 메시지 DTO 타입 부재
`@MessageBody() data: { matchId: string }` 같은 inline type 대신 class-validator DTO 정의 + `WsValidationPipe` 적용. HTTP와 동일한 검증 표준 통일.

### S2. backend/src/modules/game/game.service.ts 전반 — 구조화 로깅 부재
체포·구출·게임시작·종료·EMP·SIREN 등 결정적 이벤트에 `Logger.log({ matchId, userId, eventType })` 누락. pino 같은 구조화 로거 도입 권장.

### S3. backend/src/modules/auth/auth.service.ts:233-247 — logout 시 access token 남은 TTL 미사용
임의로 1800초를 set. JWT exp 클레임을 디코드해 `exp - now`만큼만 TTL 설정.
```typescript
const decoded = this.jwtService.decode(token) as any;
const ttl = Math.max(1, decoded.exp - Math.floor(Date.now() / 1000));
await this.redisService.set(`auth:blacklist:${token}`, '1', ttl);
```

### S4. backend/src/modules/redis/redis.service.ts — 헬퍼 부족
`setNx`, `mget`, `pipeline`, `eval`, `sadd/smembers`, `geosearch`(GEORADIUS deprecated) 누락. `set` ttl 0 가드 부재(0이면 영구 저장).

### S5. backend/src/modules/lobby/lobby.service.ts:200-230 — Redis 응답 빈 케이스 처리 모호
`redisState.game_status`가 falsy면 DB fallback인데, “Redis는 있지만 player 데이터가 비어있는” 케이스를 명시 처리하지 않음.

### S6. backend/src/modules/events/events.gateway.ts:48-50 — 헬스체크/모니터링 부재
namespace 'game' 기준 ping/pong 모니터링 없음. socket.io-admin-ui 또는 자체 telemetry 추천.

---

## 멀티플레이어 게임 서버 신뢰성 평가

### 종합 평가: 프로토타입 수준 (프로덕션 불가)

| 영역 | 평가 | 근거 |
| --- | --- | --- |
| 인증/인가 | 취약 | WS join_room 멤버십 검증 부재(C1), WS handshake 블랙리스트 미체크(C9), JWT secret 다중 출처(C9) |
| 동시성/원자성 | 다수 깨짐 | game state hash read-modify-write 비원자(C4), 팀 1회 제한 NX 미사용(C5), 호스트 위임 race(C8), join 정원 race(W6) |
| 메모리/스케일 | 위험 | 핫 경로 KEYS 명령(C7), 종료 시 expire만 1시간(C6), pipeline 미사용(W1, W2) |
| 데이터 일관성 | 분산 트랜잭션 부재 | Prisma↔Redis 보상 트랜잭션 없음(C3), endGame Prisma 트랜잭션 안 N+1(W2) |
| 입력 검증 | 부분 적용 | HTTP DTO 일부 적용/ValidationPipe 전역 OK이나, mapConfig·rules가 any(W8), WS DTO 검증 부재(S1) |
| 예외/관측성 | 부족 | WS 글로벌 예외 필터 부재(C2), 구조화 로깅 부재(S2) |
| 보안 | 보통 | room code Math.random 4자리 충돌·예측(W5), 위치 무결성 검증 자체는 존재(긍정) |
| 게임 로직 정확성 | 일부 결함 | playerKeys.filter(endsWith) 오탐(C8), selectAbility PREPARE/WAITING 모두 허용(테스트로 보증, 긍정) |

### 우선순위 권고 (실서비스 출시 전 필수)

1. **C1, C9**: WS 인증 강화 — join_room/connection 시 매치 멤버십 검증 + 블랙리스트 체크 + ConfigService 기반 secret 통합. (보안 critical)
2. **C2**: 전역 WsExceptionFilter 적용 — 모든 `@SubscribeMessage` 핸들러에서 일관된 ack 페이로드. (안정성 critical)
3. **C7**: KEYS → SADD/SMEMBERS 또는 SCAN으로 전환 — `game:{matchId}:players` SET 도입. (스케일 critical)
4. **C4, C5, C8, W6**: read-modify-write를 모두 Lua script 또는 hincrby/setNx로 교체. host 위임에 short-lived lock. (게임 정합성 critical)
5. **C6**: 종료 시 `del`(즉시 정리) + 통계용 키만 expire. SCAN + pipeline. (메모리 critical)
6. **C3, W3**: Prisma↔Redis 동기화 outbox 패턴 또는 게임 종료 시점 단일 flush로 일원화. refresh secret 분리.
7. **W1, W2**: pipeline 도입.
8. **W5**: room code를 `crypto.randomInt` + 5자리 + Redis NX reservation.
9. **W8, S1**: mapConfig/rules nested DTO + WsValidationPipe.
10. **S2, W9**: 구조화 로깅 + integrity 위반 큐화.

### 멀티플레이 게임 서버 관점 추가 권고

- **단일 매치 → 단일 leader 패턴**: 현재 모든 클라이언트가 동시에 server에 쓴다. 위치/체포 같은 이벤트는 BullMQ + worker로 매치별 직렬화하거나 actor 패턴(matchId hash 라우팅) 적용 권장.
- **시계 동기화**: serverNowMs/startTime을 클라이언트가 그대로 신뢰하면 클라이언트 타임드리프트로 능력 게이지/CLOWN 패시브 충전 변조 가능. deltaSec cap(0.5~5초) 일부 적용되어 있으나 재검증 필요.
- **재접속**: `syncGameState`는 존재하지만 WS reconnect 시 connection 핸들러가 자동 join만 하고 missed event replay 없음. last seq 기반 catchup endpoint 권장.
- **테스트 커버리지**: 현재 spec는 서비스당 1-3개 케이스 수준. 동시성 시나리오(2명 동시 ready, 동시 use SIREN, 동시 leave host)에 대한 통합 테스트 필수.
