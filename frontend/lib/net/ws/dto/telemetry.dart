class TelemetryBatchPayload {
  final String matchId;
  final String playerId;
  final String device;
  final List<TelemetrySample> samples;

  const TelemetryBatchPayload({
    required this.matchId,
    required this.playerId,
    required this.device,
    required this.samples,
  });

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'playerId': playerId,
        'device': device,
        'samples': samples.map((e) => e.toJson()).toList(),
      };

  factory TelemetryBatchPayload.fromJson(Map<String, dynamic> json) {
    return TelemetryBatchPayload(
      matchId: (json['matchId'] ?? '').toString(),
      playerId: (json['playerId'] ?? '').toString(),
      device: (json['device'] ?? '').toString(),
      samples: (json['samples'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => TelemetrySample.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class TelemetrySample {
  final int tsMs;
  final double? headingDeg;
  final int? heartRateBpm;
  final int? stepCount;
  final double? speedMps;
  final double? distanceM;
  final double? confidence;

  const TelemetrySample({
    required this.tsMs,
    this.headingDeg,
    this.heartRateBpm,
    this.stepCount,
    this.speedMps,
    this.distanceM,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'tsMs': tsMs,
        if (headingDeg != null) 'headingDeg': headingDeg,
        if (heartRateBpm != null) 'heartRateBpm': heartRateBpm,
        if (stepCount != null) 'stepCount': stepCount,
        if (speedMps != null) 'speedMps': speedMps,
        if (distanceM != null) 'distanceM': distanceM,
        if (confidence != null) 'confidence': confidence,
      };

  factory TelemetrySample.fromJson(Map<String, dynamic> json) {
    return TelemetrySample(
      tsMs: (json['tsMs'] as num?)?.toInt() ?? 0,
      headingDeg: (json['headingDeg'] as num?)?.toDouble(),
      heartRateBpm: (json['heartRateBpm'] as num?)?.toInt(),
      stepCount: (json['stepCount'] as num?)?.toInt(),
      speedMps: (json['speedMps'] as num?)?.toDouble(),
      distanceM: (json['distanceM'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

class TelemetryHintPayload {
  final String forPlayerId;
  final int hz;
  final int ttlMs;
  final String reason;

  const TelemetryHintPayload({
    required this.forPlayerId,
    required this.hz,
    required this.ttlMs,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'forPlayerId': forPlayerId,
        'hz': hz,
        'ttlMs': ttlMs,
        'reason': reason,
      };

  factory TelemetryHintPayload.fromJson(Map<String, dynamic> json) {
    return TelemetryHintPayload(
      forPlayerId: (json['forPlayerId'] ?? '').toString(),
      hz: (json['hz'] as num?)?.toInt() ?? 0,
      ttlMs: (json['ttlMs'] as num?)?.toInt() ?? 0,
      reason: (json['reason'] ?? '').toString(),
    );
  }
}

