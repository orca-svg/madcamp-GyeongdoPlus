# Frontend

## Setup

```bash
cd frontend
make get
```

## Local Run

The app now prefers compile-time `dart-define` values instead of bundling a private `.env` file into the app.

```bash
make run-ios \
  API_BASE_URL=http://<MAC_IP>:3000 \
  SOCKET_IO_URL=http://<MAC_IP>:3000 \
  WS_URL=ws://<MAC_IP>:3000/v1/ws \
  KAKAO_JS_APP_KEY=<your-key> \
  KAKAO_NATIVE_APP_KEY=<your-key>
```

Example for Android emulator:

```bash
make run-android \
  API_BASE_URL=http://10.0.2.2:3000 \
  SOCKET_IO_URL=http://10.0.2.2:3000 \
  WS_URL=ws://10.0.2.2:3000/v1/ws
```

## Checks

```bash
make analyze
make test
```

## Notes

- If Kakao map keys are not configured, map-heavy screens fall back to placeholder content instead of crashing.
- Real private values should stay in ignored local files or shell variables. See [`../frontend/.env.example`](/Users/junyeop_lee/Desktop/kaist/MadCamp/madcamp-GyeongdoPlus/frontend/.env.example) for the expected keys.
