---
name: integration-review-guide
description: GyeongdoPlus Frontend-Backend 통합 정합성 검증 가이드. integration-checker 에이전트가 사용하는 WS 프로토콜, REST API, DTO shape 비교 기준. WS 메시지 타입 불일치, DTO 필드 불일치, API 엔드포인트 불일치 검증 시 사용한다.
---

# 통합 정합성 리뷰 가이드 — GyeongdoPlus

## 경계면 지도

```
Flutter App
  └── data/api_client.dart      (REST)
  └── net/ws/ws_client.dart     (WebSocket)
  └── net/ws/ws_types.dart      (메시지 타입 열거)
  └── net/ws/dto/               (페이로드 DTO)
        ├── match_state_dto.dart
        ├── radar_ping_payload.dart
        └── telemetry_dto.dart

NestJS Backend
  └── modules/events/events.gateway.ts  (WS)
  └── modules/*/**.controller.ts        (REST)
  └── modules/*/**.dto.ts               (DTO 정의)
```

## 검증 방법론

파일 쌍을 나란히 읽어 필드명·타입·필수성을 비교한다. 단순히 "파일이 존재한다"가 아니라 **실제 필드 레벨 비교**를 수행한다.

### 1. WS 메시지 타입 전수 조사

**Frontend** `ws_types.dart`의 `WsType` enum 값들과  
**Backend** `events.gateway.ts`의 `@SubscribeMessage(...)` 핸들러 목록 비교:

예상 목록:
- `client_hello` ↔ `@SubscribeMessage('client_hello')`
- `join_match` ↔ `@SubscribeMessage('join_match')`
- `action` ↔ `@SubscribeMessage('action')`
- `telemetry_batch` ↔ `@SubscribeMessage('telemetry_batch')`

**서버→클라이언트 전용** (Frontend가 emit 안 하는 것):
- `server_hello`, `match_state`, `radar_ping`, `match_event`

불일치: Frontend에 타입이 있으나 Backend 핸들러가 없거나, 반대의 경우.

### 2. match_state DTO 심층 비교

**Frontend** `dto/match_state_dto.dart` 필드 목록과  
**Backend**에서 `match_state` 이벤트 emit 시 페이로드 구조 비교.

비교 포인트:
```
matchId       : String / string
state         : String('LOBBY'|'PREP'|'RUNNING'|'ENDED') / enum
mode          : String / string
rules.opponentReveal.radarPingTtlMs : int / number
time.serverNowMs   : int / number
time.prepEndsAtMs  : int? / number | null
time.endsAtMs      : int? / number | null
teams.police       : List<String> / string[]
teams.thief        : List<String> / string[]
players            : Map<String, MatchPlayerDto> / Record<string, PlayerDto>
live.score         : dynamic / object
```

### 3. radar_ping 페이로드 비교

**Frontend** `dto/radar_ping_payload.dart`와  
**Backend** radar_ping emit 코드:

```
forPlayerId : String / string
ttlMs       : int / number
pings[].kind        : String('ENEMY'|'ALLY'|'JAIL') / string
pings[].bearingDeg  : double / number
pings[].distanceM   : double / number
pings[].confidence  : double? / number?
```

### 4. REST API 엔드포인트 전수 조사

**Frontend** `api_client.dart`에서 호출하는 경로 목록 추출 → **Backend** controller 경로와 대조.

확인 항목:
- HTTP 메서드 일치 (GET/POST/PUT/DELETE)
- 경로 파라미터 이름 일치 (`:matchId` vs `{matchId}`)
- 요청 바디 필드 일치
- 응답 필드 일치

### 5. 인증 처리

- Frontend에서 JWT 토큰을 Authorization header에 포함하는 방식
- Backend JwtAuthGuard 적용 범위 (누락된 endpoint 없는지)
- WS 연결 시 인증 방식 (핸드셰이크 토큰 vs join_match 페이로드)

### 6. 에러 코드 처리

- Backend: `BadRequestException`, `NotFoundException`, `ForbiddenException`이 각각 400, 404, 403 응답 코드를 내보내는지
- Frontend `api_client.dart`의 에러 처리: statusCode별 분기 처리 여부
- WS 에러: emit 형식과 Frontend의 수신 처리 일치

## 비교 출력 형식

불일치 항목은 반드시 테이블로 정리:

| 항목 | Frontend | Backend | 불일치 유형 |
|------|----------|---------|-----------|
| match_state.live | `Map<String,dynamic>` | `{score: ScoreDto}` | 타입 불명확 |
| ... | | | |

**불일치 유형 분류:**
- `MISSING_HANDLER`: Frontend가 보내지만 Backend 핸들러 없음
- `MISSING_CLIENT`: Backend가 보내지만 Frontend 처리 없음
- `FIELD_MISMATCH`: 같은 데이터를 다른 필드명으로 참조
- `TYPE_MISMATCH`: 같은 필드를 다른 타입으로 처리
- `NULLABLE_MISMATCH`: 한쪽은 nullable, 반대쪽은 non-null

## 출력 형식

1. **요약** (WS/REST/DTO별 불일치 건수)
2. **CRITICAL 불일치** (게임 진행 불가 유발)
3. **WARNING 불일치** (런타임 에러 가능)
4. **통합 안정성 평가**
