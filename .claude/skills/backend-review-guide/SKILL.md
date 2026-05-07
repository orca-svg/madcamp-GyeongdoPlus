---
name: backend-review-guide
description: GyeongdoPlus NestJS 백엔드 코드 리뷰 가이드. backend-reviewer 에이전트가 사용하는 심층 리뷰 기준. NestJS, WebSocket Gateway, Redis, Prisma, 게임 서버 로직 리뷰 시 사용한다.
---

# Backend 코드 리뷰 가이드 — GyeongdoPlus

## 프로젝트 컨텍스트

- **경로**: `backend/src/`
- **프레임워크**: NestJS
- **DB**: PostgreSQL via Prisma
- **캐시/세션**: Redis (게임 실시간 상태)
- **실시간**: Socket.IO WebSocket Gateway

## 핵심 파일 우선순위

1. `modules/events/events.gateway.ts` — WS 진입점, 가장 중요
2. `modules/game/game.service.ts` — 게임 로직 핵심
3. `modules/lobby/lobby.service.ts` — 방 생성/입장
4. `modules/auth/auth.service.ts` — 인증

## 리뷰 기준

### CRITICAL — 즉시 수정 필요

**Redis 레이스 컨디션**

멀티플레이어 게임에서 가장 빈번한 버그 패턴:
```typescript
// 위험: read-modify-write 비원자적
const state = await redis.hgetall(`game:${matchId}:state`);
state.score = parseInt(state.score) + 1;
await redis.hset(`game:${matchId}:state`, state); // ❌ 동시 요청 시 덮어씀
```
→ `MULTI/EXEC`, Lua script, 또는 `HINCRBY` 같은 원자적 명령으로 대체

**WS Gateway 예외 미처리**
```typescript
@SubscribeMessage('action')
async handleAction(@ConnectedSocket() client: Socket, ...) {
  // try/catch 없으면 예외가 프로세스로 전파될 수 있음
}
```
→ 핸들러 내 try/catch, 또는 ExceptionFilter 적용

**게임 종료 후 Redis 키 정리 누락**
- `game:{matchId}:*` 키들이 TTL 없이 남으면 메모리 누수
- 게임 종료 시 명시적 삭제 또는 TTL 설정 확인

### WARNING — 동작하지만 위험

**Prisma N+1 쿼리**
```typescript
// N+1: 플레이어마다 DB 쿼리
for (const playerId of playerIds) {
  const player = await prisma.player.findUnique({ where: { id: playerId } }); // ❌
}
// 개선: include 또는 findMany + in
```

**환경 변수 직접 접근**
```typescript
process.env.JWT_SECRET // ❌
// 개선: ConfigService 주입
```

**DTO 유효성 검사 누락**
- `@IsString()`, `@IsUUID()`, `@IsNumber()` 등 class-validator 데코레이터 확인
- `ValidationPipe` 전역 등록 여부 (`main.ts`)

### SUGGESTION

**에러 응답 표준화**
- 모든 에러가 동일한 형식 `{ statusCode, message, error }` 반환하는지
- Frontend에서 파싱하기 쉬운 구조인지

**로깅**
- 게임 시작/종료, 체포/구출 이벤트 로그 존재 여부
- 에러 로그에 matchId, playerId 컨텍스트 포함 여부

## Redis 키 구조 검증

프로젝트에서 사용하는 키 패턴 일관성 확인:
```
game:{matchId}:state          — 게임 전역 상태 (hgetall)
game:{matchId}:player:{userId} — 플레이어 상태
lobby:{roomCode}               — 로비 상태
```

새로운 키 패턴이 위 체계를 벗어나지 않는지 확인.

## 출력 형식 (엄격히 준수)

1. **요약** (이슈 카운트)
2. **CRITICAL** (데이터 손상, 크래시, 보안 취약점)
3. **WARNING** (성능, 비표준 패턴)
4. **SUGGESTION** (선택적 개선)
5. **멀티플레이어 게임 서버 신뢰성 평가**

각 이슈: `파일명:라인번호 — 문제` + `현재 코드` + `개선안`
