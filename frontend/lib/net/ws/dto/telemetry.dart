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
  final TelemetryGps? gps;
  final TelemetryMotion? motion;
  final TelemetryPdr? pdr;
  final TelemetryHeart? heart;
  final List<TelemetryBlePeer>? blePeers;
  final List<TelemetryUwbPeer>? uwbPeers;
  final TelemetryContext? context;

  const TelemetrySample({
    required this.tMs,
    this.gps,
    this.motion,
    this.pdr,
    this.heart,
    this.blePeers,
    this.uwbPeers,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'tMs': tMs,
        if (gps != null) 'gps': gps!.toJson(),
        if (motion != null) 'motion': motion!.toJson(),
        if (pdr != null) 'pdr': pdr!.toJson(),
        if (heart != null) 'heart': heart!.toJson(),
        if (blePeers != null) 'blePeers': blePeers!.map((e) => e.toJson()).toList(),
        if (uwbPeers != null) 'uwbPeers': uwbPeers!.map((e) => e.toJson()).toList(),
        if (context != null) 'context': context!.toJson(),
      };

  factory TelemetrySample.fromJson(Map<String, dynamic> json) {
    return TelemetrySample(
      tMs: (json['tMs'] as num?)?.toInt() ?? 0,
      gps: (json['gps'] is Map) ? TelemetryGps.fromJson((json['gps'] as Map).cast<String, dynamic>()) : null,
      motion: (json['motion'] is Map) ? TelemetryMotion.fromJson((json['motion'] as Map).cast<String, dynamic>()) : null,
      pdr: (json['pdr'] is Map) ? TelemetryPdr.fromJson((json['pdr'] as Map).cast<String, dynamic>()) : null,
      heart: (json['heart'] is Map) ? TelemetryHeart.fromJson((json['heart'] as Map).cast<String, dynamic>()) : null,
      blePeers: (json['blePeers'] is List)
          ? (json['blePeers'] as List)
              .whereType<Map>()
              .map((e) => TelemetryBlePeer.fromJson(e.cast<String, dynamic>()))
              .toList()
          : null,
      uwbPeers: (json['uwbPeers'] is List)
          ? (json['uwbPeers'] as List)
              .whereType<Map>()
              .map((e) => TelemetryUwbPeer.fromJson(e.cast<String, dynamic>()))
              .toList()
          : null,
      context: (json['context'] is Map) ? TelemetryContext.fromJson((json['context'] as Map).cast<String, dynamic>()) : null,
    );
  }
}

class TelemetryGps {
  final double lat;
  final double lng;
  final double? accM;
  final double? speedMps;

  const TelemetryGps({
    required this.lat,
    required this.lng,
    this.accM,
    this.speedMps,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (accM != null) 'accM': accM,
        if (speedMps != null) 'speedMps': speedMps,
      };

  factory TelemetryGps.fromJson(Map<String, dynamic> json) {
    return TelemetryGps(
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      accM: (json['accM'] as num?)?.toDouble(),
      speedMps: (json['speedMps'] as num?)?.toDouble(),
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

class TelemetryPdr {
  final double? dxM;
  final double? dyM;
  final double? confidence;

  const TelemetryPdr({
    this.dxM,
    this.dyM,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        if (dxM != null) 'dxM': dxM,
        if (dyM != null) 'dyM': dyM,
        if (confidence != null) 'confidence': confidence,
      };

  factory TelemetryPdr.fromJson(Map<String, dynamic> json) {
    return TelemetryPdr(
      dxM: (json['dxM'] as num?)?.toDouble(),
      dyM: (json['dyM'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
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

class TelemetryBlePeer {
  final String peerId;
  final int? rssi;
  final int? txPower;
  final double? scanQ;

  const TelemetryBlePeer({
    required this.peerId,
    this.rssi,
    this.txPower,
    this.scanQ,
  });

  Map<String, dynamic> toJson() => {
        'peerId': peerId,
        if (rssi != null) 'rssi': rssi,
        if (txPower != null) 'txPower': txPower,
        if (scanQ != null) 'scanQ': scanQ,
      };

  factory TelemetryBlePeer.fromJson(Map<String, dynamic> json) {
    return TelemetryBlePeer(
      peerId: (json['peerId'] ?? '').toString(),
      rssi: (json['rssi'] as num?)?.toInt(),
      txPower: (json['txPower'] as num?)?.toInt(),
      scanQ: (json['scanQ'] as num?)?.toDouble(),
    );
  }
}

class TelemetryUwbPeer {
  final String peerId;
  final double? distanceM;
  final double? confidence;

  const TelemetryUwbPeer({
    required this.peerId,
    this.distanceM,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'peerId': peerId,
        if (distanceM != null) 'distanceM': distanceM,
        if (confidence != null) 'confidence': confidence,
      };

  factory TelemetryUwbPeer.fromJson(Map<String, dynamic> json) {
    return TelemetryUwbPeer(
      peerId: (json['peerId'] ?? '').toString(),
      distanceM: (json['distanceM'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
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
