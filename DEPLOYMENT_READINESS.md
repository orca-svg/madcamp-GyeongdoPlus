# Deployment Readiness

This file defines the current release gate for the repository and separates what can be verified automatically from what still requires real devices.

## Release Gate

The project is considered `code-ready for deployment candidate` when all of the following are true:

1. Backend build passes.
2. Backend unit tests pass.
3. Backend e2e smoke test passes.
4. Backend can expose `GET /health`.
5. Flutter analyze has no compile errors.
6. Flutter tests pass.
7. Android and WearOS Kotlin compile checks pass.
8. Secrets are not stored in tracked files.
9. Local-first run instructions are documented for a fresh clone.

## Automated Checks

These checks are currently passing in the workspace:

### Backend

```bash
cd backend
npm run prisma:generate
npm run build
npm test -- --runInBand
npm run test:e2e -- --runInBand
```

### Frontend

```bash
cd frontend
fvm flutter test
fvm flutter analyze
```

Notes:

- `flutter analyze` still returns warning/info output from legacy code, but no compile errors are currently blocking builds.
- `flutter test` passes.

### Android / WearOS

```bash
cd frontend/android
./gradlew :app:compileDebugKotlin :wear:compileDebugKotlin
```

## Local Setup For Anyone

### Backend

```bash
cd backend
cp .env.example .env
npm install
npm run prisma:generate
npm run db:migrate:deploy
npm run start:dev
```

Required local services:

- PostgreSQL or Supabase
- Redis

Fully local Docker path:

```bash
cd backend
docker compose -f docker-compose.local.yml up --build
```

### Frontend

```bash
cd frontend
make get
make run-ios \
  API_BASE_URL=http://<MAC_IP>:3000 \
  SOCKET_IO_URL=http://<MAC_IP>:3000 \
  WS_URL=ws://<MAC_IP>:3000/v1/ws
```

Optional:

- `KAKAO_JS_APP_KEY`
- `KAKAO_NATIVE_APP_KEY`

If Kakao keys are absent, map-heavy screens now fall back to placeholder content instead of crashing.

## Device-Only Checks

These still require a human with real hardware or simulator control:

1. iPhone to local backend connectivity over the same Wi-Fi.
2. Apple Watch pairing, install, and watch action delivery.
3. Real GPS permission flows.
4. Real location updates and movement behavior.
5. Real arrest and rescue behavior with two players.
6. Actual haptic delivery on phone and watch.
7. End-of-game history correctness against the live backend database.

## Manual QA Script

### A. Backend readiness

1. Run `redis-cli ping` and confirm `PONG`.
2. Run `cd backend && npm run start:dev`.
3. Confirm `Nest application successfully started`.
4. Open `http://127.0.0.1:3000/health` and confirm `ok: true`.

### B. Frontend launch

1. Start the iPhone app from Xcode or `make run-ios`.
2. Start the simulator or second device.
3. Confirm both builds point at the same backend host.

### C. Lobby flow

1. Create a room on device A.
2. Join with the room code on device B.
3. Change roles.
4. Toggle ready.
5. Confirm the start button stays disabled until all conditions are met.

### D. In-game flow

1. Start the match.
2. Confirm map or placeholder renders without crashing.
3. Confirm watch ping reaches the phone and backend.
4. Move both players close enough to test arrest.
5. Confirm arrest state stays synchronized.

### E. Post-game flow

1. End the game.
2. Open history.
3. Verify role, result, mode, duration, and distance values are sensible.

## What To Send Back After Manual QA

Use this structure:

```text
[scenario]
Lobby role sync

[environment]
- iPhone model
- Apple Watch model
- simulator or second device
- backend target (local or remote)

[expected]
- both devices show the same role immediately

[actual]
- host changed role but guest did not update

[logs]
- backend logs
- Xcode logs
- flutter logs
```
