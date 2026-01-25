class TelemetryBatchPayload {
  final String matchId;
  final String playerId;
  final TelemetryDevice device;
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
        'device': device.toJson(),
        'samples': samples.map((e) => e.toJson()).toList(),
      };

  factory TelemetryBatchPayload.fromJson(Map<String, dynamic> json) {
    return TelemetryBatchPayload(
      matchId: (json['matchId'] ?? '').toString(),
      playerId: (json['playerId'] ?? '').toString(),
      device: TelemetryDevice.fromJson((json['device'] as Map? ?? const {}).cast<String, dynamic>()),
      samples: (json['samples'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => TelemetrySample.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}


class TelemetryDevice {
  final String platform;
  final String model;

  const TelemetryDevice({
    required this.platform,
    required this.model,
  });

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'model': model,
      };

  factory TelemetryDevice.fromJson(Map<String, dynamic> json) {
    return TelemetryDevice(
      platform: (json['platform'] ?? '').toString(),
      model: (json['model'] ?? '').toString(),
    );
  }
}


class TelemetrySample {
  final int tMs;
  final TelemetryMotion? motion;
  final TelemetryHeart? heart;
  final TelemetryContext? context;

  const TelemetrySample({
    required this.tMs,
    this.motion,
    this.heart,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'tMs': tMs,
        if (motion != null) 'motion': motion!.toJson(),
        if (heart != null) 'heart': heart!.toJson(),
        if (context != null) 'context': context!.toJson(),
      };

  factory TelemetrySample.fromJson(Map<String, dynamic> json) {
    return TelemetrySample(
      tMs: (json['tMs'] as num?)?.toInt() ?? 0,
      motion: (json['motion'] is Map) ? TelemetryMotion.fromJson((json['motion'] as Map).cast<String, dynamic>()) : null,
      heart: (json['heart'] is Map) ? TelemetryHeart.fromJson((json['heart'] as Map).cast<String, dynamic>()) : null,
      context: (json['context'] is Map) ? TelemetryContext.fromJson((json['context'] as Map).cast<String, dynamic>()) : null,
    );
  }
}

class TelemetryMotion {
  final double? headingDeg;
  final int? stepCount;

  const TelemetryMotion({this.headingDeg, this.stepCount});

  Map<String, dynamic> toJson() => {
        if (headingDeg != null) 'headingDeg': headingDeg,
        if (stepCount != null) 'stepCount': stepCount,
      };

  factory TelemetryMotion.fromJson(Map<String, dynamic> json) {
    return TelemetryMotion(
      headingDeg: (json['headingDeg'] as num?)?.toDouble(),
      stepCount: (json['stepCount'] as num?)?.toInt(),
    );
  }
}

class TelemetryHeart {
  final int? bpm;

  const TelemetryHeart({this.bpm});
  

  Map<String, dynamic> toJson() => {
        if (bpm != null) 'bpm': bpm,
      };

  factory TelemetryHeart.fromJson(Map<String, dynamic> json) {
    return TelemetryHeart(
      bpm: (json['bpm'] as num?)?.toInt(),
    );
  }
}

class TelemetryContext {
  final String? mode;
  final bool? isInJailZone;
  final bool? isOutOfBounds;

  const TelemetryContext({this.mode, this.isInJailZone, this.isOutOfBounds});

  Map<String, dynamic> toJson() => {
        if (mode != null) 'mode': mode,
        if (isInJailZone != null) 'isInJailZone': isInJailZone,
        if (isOutOfBounds != null) 'isOutOfBounds': isOutOfBounds,
      };

  factory TelemetryContext.fromJson(Map<String, dynamic> json) {
    return TelemetryContext(
      mode: json['mode']?.toString(),
      isInJailZone: json['isInJailZone'] as bool?,
      isOutOfBounds: json['isOutOfBounds'] as bool?,
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

