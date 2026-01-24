enum WsType {
  clientHello,
  serverHello,
  joinMatch,
  telemetryBatch,
  telemetryHint,
  matchState,
  matchEvent,
  radarPing,
  error,
}

extension WsTypeWire on WsType {
  String get wire {
    switch (this) {
      case WsType.clientHello:
        return 'client_hello';
      case WsType.serverHello:
        return 'server_hello';
      case WsType.joinMatch:
        return 'join_match';
      case WsType.telemetryBatch:
        return 'telemetry_batch';
      case WsType.telemetryHint:
        return 'telemetry_hint';
      case WsType.matchState:
        return 'match_state';
      case WsType.matchEvent:
        return 'match_event';
      case WsType.radarPing:
        return 'radar_ping';
      case WsType.error:
        return 'error';
    }
  }
}

WsType? wsTypeFromWire(String raw) {
  switch (raw) {
    case 'client_hello':
      return WsType.clientHello;
    case 'server_hello':
      return WsType.serverHello;
    case 'join_match':
      return WsType.joinMatch;
    case 'telemetry_batch':
      return WsType.telemetryBatch;
    case 'telemetry_hint':
      return WsType.telemetryHint;
    case 'match_state':
      return WsType.matchState;
    case 'match_event':
      return WsType.matchEvent;
    case 'radar_ping':
      return WsType.radarPing;
    case 'error':
      return WsType.error;
    default:
      return null;
  }
}

