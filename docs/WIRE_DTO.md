# Wire DTO Schema Documentation

이 문서는 백엔드(Nest.js)와 프론트엔드(Flutter) 간의 통신 프로토콜을 정의합니다.

---

## 0. Socket.IO Connection

### 0.1 Configuration

**Backend**: Nest.js with Socket.IO  
**Namespace**: `/game` (default namespace)  
**URL**: `http://localhost:3000` (dev) or `SOCKET_IO_URL` env var  
**Transport**: WebSocket only (`transports: ['websocket']`)

### 0.2 Authentication

**Method**: JWT token in Socket.IO handshake

```dart
// Flutter client
socket = io.io(
  baseUrl,
  io.OptionBuilder()
    .setAuth({'token': jwtToken})
    .setQuery({'matchId': matchId})
    .build()
);
```

**Backend**: `EventsGateway.handleConnection()`
- Extracts token from `client.handshake.auth.token` or `headers.authorization`
- Verifies using `jwtService.verify(token, {secret: JWT_SECRET})`
- Attaches `userId` and `email` to `client.data`
- Auto-joins Socket.IO room if `matchId` in query

### 0.3 Connection Flow

1. **App Launch**: `BottomNavShell.initState()` initializes `socketIoRouterProvider`
2. **Room Join**: `RoomController.joinRoom()` success triggers:
   ```dart
   await socketIoClient.connect(jwtToken: token, matchId: roomId);
   socketIoClient.emitJoinRoom(roomId);
   ```
3. **Backend**: Authenticates and joins Socket.IO room
4. **Events**: All game events broadcast via `server.to(matchId).emit(...)`
5. **Room Leave**: `RoomController.leaveRoom()` calls `socketIoClient.disconnect()`

---

## 1. REST API Endpoints

### 1.1 Lobby Module (`/lobby`)

| Method | Path | Description | Request DTO | Response |
|--------|------|-------------|-------------|----------|
| POST | `/lobby/create` | 방 생성 | `CreateRoomDto` | `{success, data: {matchId, roomCode}}` |
| POST | `/lobby/join` | 방 입장 | `{roomCode}` | `{success, data: {matchId, myRole, hostId}}` |
| POST | `/lobby/kick` | 유저 강퇴 | `{matchId, targetUserId}` | `{success, data: {kickedUserId}}` |
| GET | `/lobby/:matchId` | 방 정보 조회 | - | `{success, data: {players[], settings}}` |
| PATCH | `/lobby/:matchId` | 방 설정 변경 | `UpdateRoomDto` | `{success, data: {updatedSettings}}` |
| POST | `/lobby/start` | 게임 시작 | `{matchId}` | `{success, data: {startTime, gameDuration}}` |

### 1.2 Game Module (`/game`)

| Method | Path | Description | Request DTO | Response |
|--------|------|-------------|-------------|----------|
| POST | `/game/move` | 위치 전송 | `{matchId, lat, lng, heartRate?, heading?}` | `{nearbyEvents[], autoArrestStatus?}` |
| POST | `/game/arrest` | 자수 | `{matchId, copId?}` | `{arrestedUser, prisonQueueIndex}` |
| POST | `/game/rescue` | 구출 | `{matchId}` | `{rescuedUserIds[], remainingPrisoners}` |
| POST | `/game/ability/select` | 직업 선택 | `{matchId, abilityClass}` | `{selectedClass}` |
| POST | `/game/ability/use` | 능력 사용 | `{matchId}` | `{skillType, remainingGauge, duration}` |
| POST | `/game/item/select` | 아이템 선택 | `{matchId, itemId}` | `{obtainedItem, currentInventory}` |
| POST | `/game/item/use` | 아이템 사용 | `{matchId, itemId}` | `{remainingItems, effectDuration}` |
| GET | `/game/:matchId/sync` | 게임 동기화 | - | `{gameStatus, myState, prisonQueue[]}` |
| POST | `/game/:matchId/end` | 게임 종료 | `{reason?}` | `{winnerTeam, mvpUser, resultReport}` |
| POST | `/game/:matchId/rematch` | 재경기 | - | `{newMatchId, roomCode}` |
| POST | `/game/:matchId/delegate` | 방장 위임 | `{targetUserId}` | `{newHostId}` |
| POST | `/game/:matchId/leave` | 방 퇴장 | - | `{leftUserId, penaltyApplied}` |

---

## 2. WebSocket Events

> **Backend**: Socket.IO (namespace: `/game`)
> **Frontend**: WatchConnectivity (STATE_SNAPSHOT, WATCH_ACTION)

### 2.1 Server → Client Events

| Event | Payload | Description |
|-------|---------|-------------|
| `player_moved` | `{userId, lat, lng, heading}` | 플레이어 위치 업데이트 |
| `user_arrested` | `{matchId, arrestedUserId, byPoliceId}` | 체포 발생 |
| `user_rescued` | `{matchId, rescuerId, rescuedUserIds[], remainingPrisoners}` | 구출 발생 |
| `game_over` | `{matchId, winnerTeam, mvpUser, playTime, resultReport}` | 게임 종료 |
| `host_changed` | `{matchId, previousHostId, newHostId}` | 방장 변경 |
| `user_left` | `{matchId, leftUserId, newHostId?, penaltyApplied}` | 유저 퇴장 |
| `radar_activated` | `{duration}` | 레이더 아이템 활성화 |
| `detector_vibrate` | `{userId}` | 탐지기 진동 |
| `reveal_thieves_static` | `{duration}` | 도둑 위치 공개 |
| `police_revealed_by_decoy` | `{policeId, decoyOwner, duration}` | 미끼에 의한 경찰 위치 공개 |
| `emp_activated` | `{duration}` | EMP 활성화 |
| `ability_silenced` | `{targetId, duration}` | 능력 침묵 |

### 2.2 Client → Server Events

| Event | Payload | Description |
|-------|---------|-------------|
| `join_room` | `{matchId}` | 방 입장 (연결 시) |

---

## 3. Watch Connectivity Protocol

### 3.1 Phone → Watch: STATE_SNAPSHOT

```json
{
  "type": "STATE_SNAPSHOT",
  "ts": 1706350000000,
  "matchId": "uuid-match-id",
  "payload": {
    "phase": "IN_GAME",
    "activeTab": "INGAME_RADAR",
    "team": "POLICE",
    "mode": "NORMAL",
    "timeRemainSec": 540,
    "counts": {
      "police": 3,
      "thiefAlive": 5,
      "thiefCaptured": 2,
      "rescueRate": 0.286
    },
    "my": {
      "distanceM": 1200,
      "captures": 2,
      "rescues": 0,
      "escapeSec": 0,
      "hr": 95,
      "hrMax": 142
    },
    "profile": {
      "nickname": "Player1",
      "policeRank": "BRONZE",
      "thiefRank": "SILVER",
      "isReady": true
    },
    "rulesLite": {
      "contactMode": "CONTACT",
      "releaseScope": "PARTIAL",
      "releaseOrder": "FIFO",
      "jailEnabled": true,
      "jailRadiusM": 12,
      "zonePoints": 5
    },
    "nearby": {
      "allyCount10m": 2,
      "enemyNear": false
    },
    "modeOptions": {}
  }
}
```

### 3.2 Phone → Watch: RADAR_PACKET

```json
{
  "type": "RADAR_PACKET",
  "headingDeg": 45.5,
  "ttlMs": 3000,
  "pings": [
    {"kind": "ENEMY", "bearingDeg": 90.0, "distanceM": 25.5, "confidence": 0.9}
  ],
  "captureProgress01": 0.75,
  "warningDirectionDeg": 180.0
}
```

### 3.3 Phone → Watch: HAPTIC_ALERT

```json
{
  "type": "HAPTIC_ALERT",
  "ts": 1706350000000,
  "matchId": "uuid-match-id",
  "payload": {
    "kind": "ENEMY_NEAR_5M",
    "cooldownSec": 5,
    "durationMs": 300
  }
}
```

### 3.4 Watch → Phone: WATCH_ACTION

```json
{
  "type": "WATCH_ACTION",
  "ts": 1706350000000,
  "matchId": "uuid-match-id",
  "payload": {
    "action": "OPEN_TAB",
    "value": "INGAME_RADAR"
  }
}
```

**Supported Actions:**
| Action | Value | Description |
|--------|-------|-------------|
| `OPEN_TAB` | Tab wire string | 탭 변경 요청 |
| `READY_TOGGLE` | `null` | 준비 상태 토글 |
| `SELECT_TEAM` | `"POLICE"` or `"THIEF"` | 팀 선택 |
| `PING` | `null` | 핑 전송 |

---

## 4. Active Tab Wire Strings

| Phase | Index | Wire String | Description |
|-------|-------|-------------|-------------|
| OFF_GAME | 0 | `OFFGAME_HOME` | 홈 화면 |
| OFF_GAME | 1 | `OFFGAME_RECENT` | 최근 경기 |
| OFF_GAME | 2 | `OFFGAME_PROFILE` | 내 정보 |
| LOBBY | 0 | `LOBBY_MAIN` | 로비 메인 |
| IN_GAME | 0 | `INGAME_RADAR` | 레이더 |
| IN_GAME | 1 | `INGAME_MAP` | 지도 |
| IN_GAME | 2 | `INGAME_CAPTURE` | 체포 |
| IN_GAME | 3 | `INGAME_SETTINGS` | 설정 |
| POST_GAME | 0 | `POSTGAME_SUMMARY` | 결과 |

---

## 5. Phase Values

| Frontend (Flutter) | Wire String | Description |
|-------------------|-------------|-------------|
| `GamePhase.offGame` | `OFF_GAME` | 게임 전 |
| `GamePhase.lobby` | `LOBBY` | 대기실 |
| `GamePhase.inGame` | `IN_GAME` | 게임 중 |
| `GamePhase.postGame` | `POST_GAME` | 게임 후 |

---

## 6. Compatibility Rules

### 6.1 Field Aliases

프론트엔드 파서는 다음 필드 alias를 지원합니다:

| Standard | Aliases |
|----------|---------|
| `hrMax` | `maxHr`, `heartRateMax` |
| `distanceM` | `distance`, `distanceMeters` |
| `bearingDeg` | `bearing`, `degrees` |

### 6.2 Phase String Normalization

```dart
String normalizePhase(String raw) {
  return raw.toUpperCase().replaceAll(' ', '_');
}
// "in game" → "IN_GAME"
// "offgame" → "OFFGAME" → handled as OFF_GAME by contains check
```

### 6.3 Null Safety

모든 필드는 optional로 처리되며, 누락 시 기본값 사용:
- `int` → `0`
- `String` → `"UNKNOWN"` or `""`
- `bool` → `false`
- `List` → `[]`

---

## 7. Testing Scenarios

### 7.1 REST Connection
```bash
# Backend 실행
cd backend && npm run start:dev

# 테스트 (Swagger)
open http://localhost:3000/api
```

### 7.2 Watch Tab Mirroring
1. 폰 탭 변경 → 워치 `activeTab` 미러링 확인
2. 워치에서 `OPEN_TAB` 전송 → 폰 탭 변경 확인
3. Phase 전환 시 기본 탭 리셋 확인

### 7.3 Haptic Alerts
1. 도둑 팀 + 적 5m 이내 → HAPTIC_ALERT 전송
2. 쿨다운(5초) 내 중복 발송 안 됨 확인
