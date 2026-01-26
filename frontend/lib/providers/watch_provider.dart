// Watch connection state provider with periodic refresh.
// Why: avoid stale "connected" status when the watch disconnects later.
// Adds a 5s timer that rechecks pairing/connection, with safe cleanup.
// Ensures errors from the bridge do not crash UI; falls back to false.
// Keeps init() and manual refresh() behavior intact for existing flows.
// Maintains lightweight state (bool) to keep consumers simple.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../watch/watch_bridge.dart';

final watchConnectedProvider =
    NotifierProvider<WatchConnectedController, bool>(
  WatchConnectedController.new,
);

class WatchConnectedController extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    _ensurePeriodicRefresh();
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    return false;
  }

  Future<void> init() async {
    try {
      await WatchBridge.init();
      state = await WatchBridge.isPairedOrConnected();
    } catch (_) {
      state = false;
    }
  }

  Future<void> refresh() async {
    try {
      state = await WatchBridge.isPairedOrConnected();
    } catch (_) {
      state = false;
    }
  }

  void _ensurePeriodicRefresh() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      refresh();
    });
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

final watchRadarVectorProvider =
    NotifierProvider<WatchRadarVectorController, WatchRadarVector?>(
  WatchRadarVectorController.new,
);

class WatchRadarVectorController extends Notifier<WatchRadarVector?> {
  @override
  WatchRadarVector? build() => null;

  void setLastRadarVector(WatchRadarVector v) => state = v;

  void clear() => state = null;
}
