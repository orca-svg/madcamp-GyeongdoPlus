import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../watch/watch_bridge.dart';

final watchConnectedProvider = NotifierProvider<WatchConnectedController, bool>(WatchConnectedController.new);

class WatchConnectedController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> init() async {
    await WatchBridge.init();
    state = await WatchBridge.isPairedOrConnected();
  }

  Future<void> refresh() async {
    state = await WatchBridge.isPairedOrConnected();
  }
}

class WatchRadarVector {
  final double headingDeg;
  final int ttlMs;
  final List<WatchRadarPing> pings;
  final double? captureProgress01;

  const WatchRadarVector({
    required this.headingDeg,
    required this.ttlMs,
    required this.pings,
    required this.captureProgress01,
  });

  Map<String, dynamic> toJson() => {
        'headingDeg': headingDeg,
        'ttlMs': ttlMs,
        'pings': pings.map((e) => e.toJson()).toList(),
        if (captureProgress01 != null) 'captureProgress01': captureProgress01,
      };
}

class WatchRadarPing {
  final String kind;
  final double bearingDeg;
  final double distanceM;
  final double? confidence;

  const WatchRadarPing({
    required this.kind,
    required this.bearingDeg,
    required this.distanceM,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'bearingDeg': bearingDeg,
        'distanceM': distanceM,
        if (confidence != null) 'confidence': confidence,
      };
}

final watchRadarVectorProvider = NotifierProvider<WatchRadarVectorController, WatchRadarVector?>(WatchRadarVectorController.new);

class WatchRadarVectorController extends Notifier<WatchRadarVector?> {
  @override
  WatchRadarVector? build() => null;

  void setLastRadarVector(WatchRadarVector v) => state = v;

  void clear() => state = null;
}
