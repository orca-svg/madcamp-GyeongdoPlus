import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' show max;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../net/ws/builders/ws_builders.dart';
import '../net/ws/dto/telemetry.dart';
import '../net/ws/ws_client.dart';
import 'game_phase_provider.dart';
import 'match_sync_provider.dart';
import 'room_provider.dart';
import '../watch/watch_sync_controller.dart';

class TelemetrySchedulerState {
  final bool running;
  final double effectiveHz;
  final int? boostUntilMs;

  const TelemetrySchedulerState({
    required this.running,
    required this.effectiveHz,
    required this.boostUntilMs,
  });

  factory TelemetrySchedulerState.initial() => const TelemetrySchedulerState(
        running: false,
        effectiveHz: 1.0,
        boostUntilMs: null,
      );

  TelemetrySchedulerState copyWith({bool? running, double? effectiveHz, int? boostUntilMs}) {
    return TelemetrySchedulerState(
      running: running ?? this.running,
      effectiveHz: effectiveHz ?? this.effectiveHz,
      boostUntilMs: boostUntilMs ?? this.boostUntilMs,
    );
  }
}

final telemetrySchedulerProvider =
    NotifierProvider<TelemetrySchedulerController, TelemetrySchedulerState>(TelemetrySchedulerController.new);

class TelemetrySchedulerController extends Notifier<TelemetrySchedulerState> {
  Timer? _timer;
  WsClient? _client;

  int _boostHz = 0;
  int _boostUntilMs = 0;

  final _buffer = <TelemetrySample>[];
  int _lastSendMs = 0;

  @override
  TelemetrySchedulerState build() {
    ref.onDispose(() => _timer?.cancel());
    return TelemetrySchedulerState.initial();
  }

  Future<void> start() async {
    if (state.running) return;

    // Ensure GPS permission before starting
    final p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) {
        debugPrint('[TELEMETRY] Permission denied - cannot start');
        return;
      }
    }

    state = state.copyWith(running: true);
    _scheduleNextTick();
  }

  void startWithClient(WsClient client) {
    _client = client;
    start();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(running: false);
  }

  void applyHint(TelemetryHintPayload hint) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _boostHz = hint.hz.clamp(1, 10);
    _boostUntilMs = now + hint.ttlMs.clamp(0, 20000);
    state = state.copyWith(effectiveHz: _computeHz(now), boostUntilMs: _boostUntilMs);
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    _timer = null;
    if (!state.running) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final hz = _computeHz(now);
    state = state.copyWith(effectiveHz: hz, boostUntilMs: _boostUntilMs > now ? _boostUntilMs : null);

    final intervalMs = max(100, (1000 / hz).round());
    _timer = Timer(Duration(milliseconds: intervalMs), () => _tick());
  }

  double _computeHz(int nowMs) {
    final phase = ref.read(gamePhaseProvider);
    final baseHz = switch (phase) {
      GamePhase.offGame => 0.2,
      GamePhase.lobby => 0.5,
      GamePhase.inGame => 1.0,
      GamePhase.postGame => 0.2,
    };

    var hz = baseHz;
    if (_boostUntilMs > nowMs) {
      hz = max(hz, _boostHz.toDouble());
    } else {
      _boostHz = 0;
      _boostUntilMs = 0;
    }
    return hz.clamp(0.2, 10.0);
  }

  Future<void> _tick() async {
    if (!state.running) return;

    final client = _client;
    if (client == null) {
      _scheduleNextTick();
      return;
    }

    final room = ref.read(roomProvider);
    final sync = ref.read(matchSyncProvider);
    final matchId = sync.lastMatchState?.payload.matchId ?? sync.currentMatchId;
    final playerId = room.myId;
    if (matchId == null || matchId.isEmpty || playerId.isEmpty) {
      _scheduleNextTick();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    _buffer.add(await _buildRealSample(now));
    while (_buffer.length > 20) {
      _buffer.removeAt(0);
    }

    if (client.isConnected) {
      final shouldFlush = _buffer.length >= 5 || (now - _lastSendMs) >= 1200;
      if (shouldFlush) {
        final batch = _buffer.take(5).toList();
        _buffer.removeRange(0, batch.length);
        _lastSendMs = now;

        final platform = Platform.isIOS ? 'ios' : 'android';
        final payload = TelemetryBatchPayload(
          matchId: matchId,
          playerId: playerId,
          device: TelemetryDevice(platform: platform, model: 'unknown'),
          samples: batch,
        );

        final env = buildTelemetryBatch(payload: payload, matchId: matchId);
        client.sendEnvelope(env, (p) => p.toJson());
      }
    }

    _scheduleNextTick();
  }

  /// Build a telemetry sample using real device GPS data.
  /// Falls back to a GPS-less sample if location cannot be obtained.
  Future<TelemetrySample> _buildRealSample(int nowMs) async {
    TelemetryGps? gps;
    double? heading;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      );
      gps = TelemetryGps(
        lat: pos.latitude,
        lng: pos.longitude,
        accM: pos.accuracy,
        speedMps: pos.speed >= 0 ? pos.speed : null,
      );
      heading = pos.heading;
    } catch (e) {
      debugPrint('[TELEMETRY] GPS unavailable: $e');
    }

    // Get Heart Rate from Watch if available
    TelemetryHeart? heart;
    try {
      final watchSync = ref.read(watchSyncControllerProvider);
      if ((watchSync.currentHeartRate ?? 0) > 0) {
        heart = TelemetryHeart(bpm: watchSync.currentHeartRate!);
      }
    } catch (_) {}

    final mode = ref.read(gamePhaseProvider).name;
    return TelemetrySample(
      tMs: nowMs,
      gps: gps,
      heart: heart,
      motion: heading != null ? TelemetryMotion(headingDeg: heading) : null,
      context: TelemetryContext(mode: mode),
    );
  }
}
