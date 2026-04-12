# Physical Device Testing

This document is intentionally generic so it is safe to keep in a public repository.

## Before You Start

- Run the backend locally.
- Confirm Redis is reachable.
- Decide whether the app will talk to a local backend or a remote backend.
- If using a local backend, use your Mac's LAN IP for `API_BASE_URL` and `SOCKET_IO_URL`.

## iPhone + Apple Watch

1. Open `frontend/ios/Runner.xcworkspace` in Xcode.
2. Configure signing for both the iPhone app and the watch app.
3. Choose a real iPhone as the active device.
4. Build and run.
5. Allow location, local network, Bluetooth, and notification permissions.
6. Install the watch app from the Watch app if auto-install does not happen.

## What To Look For

### Connection

- Socket.IO connects to `/game`
- lobby events are received
- watch state snapshots are delivered

### Lobby

- room code appears
- members sync in real time
- role and ready state changes sync across devices
- start remains blocked until conditions are satisfied

### In-Game

- location permissions are handled gracefully
- map and radar screens load
- watch ping reaches the phone and backend
- arrest and rescue state changes propagate correctly

## Logs To Capture

- backend terminal logs
- Xcode console logs
- Flutter run logs for simulator or Android devices

Filter keywords:

- `SOCKET.IO`
- `ROOM`
- `WATCH`
- `GAME`
- `ITEM`

## Recommended Reference

For the full end-to-end checklist and current readiness gates, use:

- [DEPLOYMENT_READINESS.md](/Users/junyeop_lee/Desktop/kaist/MadCamp/madcamp-GyeongdoPlus/DEPLOYMENT_READINESS.md)
