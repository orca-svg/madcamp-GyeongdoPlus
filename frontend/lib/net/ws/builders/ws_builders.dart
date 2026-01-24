import '../dto/telemetry.dart';
import '../ws_envelope.dart';
import '../ws_types.dart';

WsEnvelope<Map<String, dynamic>> buildClientHello({
  required String device,
  String? appVersion,
}) {
  return WsEnvelope<Map<String, dynamic>>(
    v: 1,
    type: WsType.clientHello,
    matchId: null,
    seq: null,
    ts: DateTime.now().millisecondsSinceEpoch,
    payload: {
      'device': device,
      if (appVersion != null) 'appVersion': appVersion,
    },
  );
}

WsEnvelope<Map<String, dynamic>> buildJoinMatch({
  required String matchId,
  required String playerId,
  String? roomCode,
}) {
  return WsEnvelope<Map<String, dynamic>>(
    v: 1,
    type: WsType.joinMatch,
    matchId: matchId,
    seq: null,
    ts: DateTime.now().millisecondsSinceEpoch,
    payload: {
      'matchId': matchId,
      'playerId': playerId,
      if (roomCode != null) 'roomCode': roomCode,
    },
  );
}

WsEnvelope<Map<String, dynamic>> buildRequestSync({
  required String matchId,
  int? lastSeq,
  String? reason,
}) {
  return WsEnvelope<Map<String, dynamic>>(
    v: 1,
    type: WsType.action,
    matchId: matchId,
    seq: null,
    ts: DateTime.now().millisecondsSinceEpoch,
    payload: {
      'action': 'REQUEST_SYNC',
      if (lastSeq != null) 'lastSeq': lastSeq,
      if (reason != null) 'reason': reason,
    },
  );
}

WsEnvelope<TelemetryBatchPayload> buildTelemetryBatch({
  required TelemetryBatchPayload payload,
  required String matchId,
}) {
  return WsEnvelope<TelemetryBatchPayload>(
    v: 1,
    type: WsType.telemetryBatch,
    matchId: matchId,
    seq: null,
    ts: DateTime.now().millisecondsSinceEpoch,
    payload: payload,
  );
}

