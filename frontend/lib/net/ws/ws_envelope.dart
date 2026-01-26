import 'ws_types.dart';

class WsEnvelope<T> {
  final int v;
  final WsType type;
  final String? matchId;
  final int? seq;
  final int? ts;
  final T payload;

  const WsEnvelope({
    required this.v,
    required this.type,
    required this.payload,
    this.matchId,
    this.seq,
    this.ts,
  });

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) payloadToJson) {
    return {
      'v': v,
      'type': type.wire,
      if (matchId != null) 'matchId': matchId,
      if (seq != null) 'seq': seq,
      if (ts != null) 'ts': ts,
      'payload': payloadToJson(payload),
    };
  }

  static WsEnvelope<T> fromJson<T>({
    required Map<String, dynamic> json,
    required T Function(Object? raw) payloadFromJson,
  }) {
    final typeWire = (json['type'] ?? '').toString();
    final t = wsTypeFromWire(typeWire);
    if (t == null) {
      throw FormatException('Unknown ws envelope type: $typeWire');
    }
    return WsEnvelope<T>(
      v: (json['v'] as num?)?.toInt() ?? 1,
      type: t,
      matchId: json['matchId']?.toString(),
      seq: (json['seq'] as num?)?.toInt(),
      ts: (json['ts'] as num?)?.toInt(),
      payload: payloadFromJson(json['payload']),
    );
  }
}

