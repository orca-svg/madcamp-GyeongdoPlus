# GyeongdoPlus

GyeongdoPlus is a multiplayer location-based `Police vs Thief` game built with Flutter, NestJS, Redis, and PostgreSQL. The current repository is organized for `local-first` development so the full stack can be exercised on one machine before moving to a remote deployment target.

## Stack

- Mobile: Flutter
- Backend: NestJS + Socket.IO
- Realtime state: Redis
- Persistent storage: PostgreSQL / Supabase
- Auth: Kakao OAuth
- Wearables: watchOS and WearOS companion flows

## Public Repo Safety

- Real credentials are ignored via `.gitignore`.
- Use the example files instead:
  - [`.env.example`](/Users/junyeop_lee/Desktop/kaist/MadCamp/madcamp-GyeongdoPlus/.env.example)
  - [`backend/.env.example`](/Users/junyeop_lee/Desktop/kaist/MadCamp/madcamp-GyeongdoPlus/backend/.env.example)
  - [`frontend/.env.example`](/Users/junyeop_lee/Desktop/kaist/MadCamp/madcamp-GyeongdoPlus/frontend/.env.example)
- Internal or local-only markdown should live under ignored patterns such as `docs/private/`, `*.internal.md`, or `*.local.md`.

## Local Run

Backend:

```bash
cd backend
npm install
npm run build
npm run start:dev
```

Frontend:

```bash
cd frontend
make get
make run-ios API_BASE_URL=http://<MAC_IP>:3000 SOCKET_IO_URL=http://<MAC_IP>:3000 WS_URL=ws://<MAC_IP>:3000/v1/ws
```

For Android emulator, use `10.0.2.2` instead of `127.0.0.1` or your Mac IP when needed.

## Health Check

The backend now exposes:

```text
GET /health
```

Expected response:

```json
{
  "ok": true,
  "service": "gyeongdoplus-backend",
  "timestamp": "2026-03-18T00:00:00.000Z"
}
```

## Verification

See [DEPLOYMENT_READINESS.md](/Users/junyeop_lee/Desktop/kaist/MadCamp/madcamp-GyeongdoPlus/DEPLOYMENT_READINESS.md) for the automated checks that currently pass and the manual/device-only checks that still need human verification.
