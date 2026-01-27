# iPhone 15 Pro + Apple Watch 실물 기기 테스트 가이드

## 현재 설정 상태 ✅

### 1. 백엔드 서버
- ✅ Redis 실행 중 (`brew services start redis`)
- ✅ Nest.js 서버 실행 중 (`npm run start:dev`)
- ✅ Socket.IO 게이트웨이 초기화 완료
- ⚠️ Redis 비밀번호 경고 (무시 가능)

### 2. 네트워크 설정
- **Mac IP**: `192.0.0.2`
- **Flutter 환경 변수**: `.env` 파일에 `SOCKET_IO_URL=http://192.0.0.2:3000` 설정됨
- **Info.plist**: 로컬 네트워크 권한 추가됨

### 3. iOS 권한 설정
- ✅ `NSLocalNetworkUsageDescription` 추가
- ✅ `NSBonjourServices` 추가 (`_http._tcp`, `_ws._tcp`)

---

## Xcode에서 빌드 및 실행

### Step 1: Xcode 열기
```bash
open /Users/junyeop_lee/Desktop/MadCamp/madcamp-GyeongdoPlus/frontend/ios/Runner.xcworkspace
```

### Step 2: 서명 설정 (Signing & Capabilities)

#### iPhone 앱 (Runner)
1. 좌측 네비게이터에서 `Runner` 프로젝트 클릭
2. **TARGETS** → `Runner` 선택
3. **Signing & Capabilities** 탭 클릭
4. **Team**: 본인의 Apple ID 선택
5. **Bundle Identifier**: 고유한 값으로 변경 (예: `com.yourname.gyeongdoplus`)

#### Watch 앱 (GyeongdoPlusWatch Watch App)
1. **TARGETS** → `GyeongdoPlusWatch Watch App` 선택
2. **Signing & Capabilities** 탭 클릭
3. **Team**: 동일한 Apple ID 선택
4. **Bundle Identifier**: 자동으로 설정됨 (보통 `com.yourname.gyeongdoplus.watchkitapp`)

### Step 3: 기기 선택 및 실행
1. Xcode 상단 스키마 선택기에서:
   - **Scheme**: `Runner` 선택
   - **Device**: `이준엽의 iPhone 15 PRO` 선택
2. **Cmd + R** 눌러서 빌드 및 실행

### Step 4: 신뢰 설정 (최초 1회)
앱이 설치되면 iPhone에서:
1. **설정** → **일반** → **VPN 및 기기 관리**
2. 본인 이메일 선택
3. **"신뢰"** 터치

### Step 5: 로컬 네트워크 권한 허용
앱 실행 시 팝업이 뜨면:
- **"로컬 네트워크에 있는 기기를 찾고 연결..."**
- 반드시 **[허용]** 선택 (Nest.js 통신 필수)

### Step 6: Watch 앱 설치
- iPhone에 앱이 설치되면 잠시 후 Apple Watch에도 자동 설치
- 안 되면: iPhone **Watch** 앱 → **나의 시계** → 하단 **사용 가능한 앱**에서 수동 설치

---

## 테스트 시나리오

### A. Socket.IO 연결 테스트

**기대 동작**:
1. 앱 실행 시 Socket.IO 연결 시도
2. Xcode 콘솔에서 확인:
   ```
   [SOCKET.IO] Connecting to http://192.0.0.2:3000/game
   [SOCKET.IO] Connected (epoch=1)
   ```
3. 백엔드 콘솔에서 확인:
   ```
   [EventsGateway] User {userId} connected
   ```

**문제 발생 시**:
- iPhone과 Mac이 **같은 Wi-Fi**에 연결되어 있는지 확인
- Mac 방화벽이 3000 포트를 막고 있지 않은지 확인
- 로컬 네트워크 권한을 **허용**했는지 확인

### B. 방 입장 테스트

**기대 동작**:
1. 앱에서 방 입장 시도
2. Xcode 콘솔:
   ```
   [ROOM] join success/roomId={roomId}
   [ROOM] Socket.IO connected and joined room
   [SOCKET.IO][ROUTER] Event: joined_room - {matchId: ...}
   ```
3. 백엔드 콘솔:
   ```
   [EventsGateway] User {userId} joined room {matchId}
   ```

### C. Watch 연동 테스트

**기대 동작**:
1. iPhone 탭 변경 → Watch 화면 즉시 전환
2. Watch에서 탭 터치 → iPhone 화면 전환
3. Xcode 콘솔:
   ```
   [WATCH] Rx: STATE_SNAPSHOT
   [WATCH] Tx: WATCH_ACTION
   ```

---

## 로그 확인 방법

### Xcode 콘솔 필터
Xcode 하단 콘솔 창에서 필터 설정:
- `[SOCKET.IO]` - Socket.IO 관련 로그
- `[ROOM]` - 방 입장/퇴장 로그
- `[WATCH]` - Watch Connectivity 로그

### 백엔드 로그
터미널에서 실시간 확인:
```bash
# 백엔드 서버 로그 (이미 실행 중)
cd /Users/junyeop_lee/Desktop/MadCamp/madcamp-GyeongdoPlus/backend
# npm run start:dev (이미 실행 중)
```

---

## 문제 해결 (Troubleshooting)

### Q: Watch 앱이 설치되지 않아요
**A**: 
- iPhone과 Watch의 OS 버전이 Xcode SDK와 호환되는지 확인
- iPhone 배터리가 충분한지 확인 (부족하면 설치 지연)
- iPhone **Watch** 앱에서 수동 설치 시도

### Q: Socket.IO 연결 실패 (Connection Refused)
**A**:
1. iPhone과 Mac이 **같은 Wi-Fi**인지 확인 (5G/2G 구분 주의)
2. Mac 방화벽 확인:
   ```bash
   # 방화벽 상태 확인
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
   ```
3. 로컬 네트워크 권한 확인 (iPhone 설정 → 개인정보 보호 → 로컬 네트워크)

### Q: Watch App 빌드 에러
**A**:
- Xcode에서 **Product** → **Clean Build Folder** (Cmd + Shift + K)
- Watch App 서명 설정 확인
- Xcode 재시작

### Q: Redis 연결 에러
**A**:
```bash
# Redis 상태 확인
brew services list | grep redis

# Redis 재시작
brew services restart redis
```

---

## 현재 시스템 상태

### 실행 중인 서비스
```
✅ Redis: localhost:6379
✅ Nest.js: http://192.0.0.2:3000
✅ Socket.IO: ws://192.0.0.2:3000/game
```

### 네트워크 설정
```
Mac IP: 192.0.0.2
Flutter: SOCKET_IO_URL=http://192.0.0.2:3000
```

### 다음 단계
1. Xcode에서 **Cmd + R** 실행
2. 로그 확인
3. Socket.IO 연결 테스트
4. Watch 연동 테스트

---

## 참고 사항

### 개발자 계정
- **무료 계정**: 7일마다 재설치 필요
- **유료 계정**: 1년간 유효

### 디버깅 팁
- Xcode 콘솔에서 실시간 로그 확인
- 백엔드 터미널에서 Socket.IO 이벤트 확인
- Watch 앱은 iPhone과 페어링 상태에서만 작동

### 성능 최적화
- USB-C 케이블 사용 (무선보다 빠름)
- Release 빌드는 `flutter build ios` 사용
- 개발 중에는 Debug 빌드 권장

## 테스트 방법
- frontend 프로젝트에서 fvm flutter pub get 실행
- cd ios로 ios 폴더 이동 /opt/homebrew/opt/ruby/bin/bundle exec pod install
