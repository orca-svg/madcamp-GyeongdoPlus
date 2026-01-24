class RadarPingDto {
  final String kind; // "JAIL" | "NEAREST_THIEF" | "ALLY" | "ENEMY" 등
  final double bearingDeg; // 0~360
  final double distanceM;
  final double confidence; // 0~1

  const RadarPingDto({
    required this.kind,
    required this.bearingDeg,
    required this.distanceM,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        "kind": kind,
        "bearingDeg": bearingDeg,
        "distanceM": distanceM,
        "confidence": confidence,
      };
}

class RadarPacketDto {
  final double headingDeg;
  final int ttlMs;
  final List<RadarPingDto> pings;
  final double? captureProgress01;
  final double? warningDirectionDeg;

  const RadarPacketDto({
    required this.headingDeg,
    required this.ttlMs,
    required this.pings,
    this.captureProgress01,
    this.warningDirectionDeg,
  });

  Map<String, dynamic> toJson() => {
        "headingDeg": headingDeg,
        "ttlMs": ttlMs,
        "pings": pings.map((e) => e.toJson()).toList(),
        "captureProgress01": captureProgress01,
        "warningDirectionDeg": warningDirectionDeg,
      };
}
