class RadarPingPayload {
  final String forPlayerId;
  final int ttlMs;
  final List<RadarPingVector> pings;

  const RadarPingPayload({
    required this.forPlayerId,
    required this.ttlMs,
    required this.pings,
  });

  Map<String, dynamic> toJson() => {
        'forPlayerId': forPlayerId,
        'ttlMs': ttlMs,
        'pings': pings.map((e) => e.toJson()).toList(),
      };

  factory RadarPingPayload.fromJson(Map<String, dynamic> json) {
    return RadarPingPayload(
      forPlayerId: (json['forPlayerId'] ?? '').toString(),
      ttlMs: (json['ttlMs'] as num?)?.toInt() ?? 0,
      pings: (json['pings'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => RadarPingVector.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class RadarPingVector {
  final String kind; // server-defined string
  final double bearingDeg; // 0..360
  final double distanceM;
  final double? confidence; // 0..1

  const RadarPingVector({
    required this.kind,
    required this.bearingDeg,
    required this.distanceM,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'bearingDeg': bearingDeg,
        'distanceM': distanceM,
        if (confidence != null) 'confidence': confidence,
      };

  factory RadarPingVector.fromJson(Map<String, dynamic> json) {
    return RadarPingVector(
      kind: (json['kind'] ?? '').toString(),
      bearingDeg: (json['bearingDeg'] as num?)?.toDouble() ?? 0,
      distanceM: (json['distanceM'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

