import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../net/ws/builders/ws_builders.dart';
import '../net/ws/dto/telemetry.dart';
import '../net/ws/ws_client.dart';
import 'game_phase_provider.dart';
import 'match_sync_provider.dart';
import 'room_provider.dart';

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
  final _rng = Random();
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

  void start() {
    if (state.running) return;
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
    _buffer.clear();
    _client = null;
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
    _timer = Timer(Duration(milliseconds: intervalMs), _tick);
  }

  double _computeHz(int nowMs) {
    final phase = ref.read(gamePhaseProvider);
    final baseHz = 1.0;
    final idleHz = (phase == GamePhase.offGame) ? 0.5 : baseHz;

    var hz = idleHz;
    if (_boostUntilMs > nowMs) {
      hz = max(hz, _boostHz.toDouble());
    } else {
      _boostHz = 0;
      _boostUntilMs = 0;
    }
    return hz.clamp(0.5, 10.0);
  }

  void _tick() {
    if (!state.running) return;

    final client = _client;
    if (client == null) {
      _scheduleNextTick();
      return;
    }
    if (!client.isConnected) {
      _scheduleNextTick();
      return;
    }

    final room = ref.read(roomProvider);
    final matchId = ref.read(matchSyncProvider).lastMatchState?.payload.matchId;
    final playerId = room.myId;
    if (matchId == null || matchId.isEmpty || playerId.isEmpty) {
      _scheduleNextTick();
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    _buffer.add(_mockSample(now));

    final shouldFlush = _buffer.length >= 5 || (now - _lastSendMs) >= 1200;
    if (shouldFlush) {
      final payload = TelemetryBatchPayload(
        matchId: matchId,
        playerId: playerId,
        device: const TelemetryDevice(
          platform: 'mobile',
          model: 'phone',
        ),
        samples: List.of(_buffer),
      );
      _buffer.clear();
      _lastSendMs = now;

      final env = buildTelemetryBatch(payload: payload, matchId: matchId);
      client.sendEnvelope(env, (p) => p.toJson());
    }

    _scheduleNextTick();
  }

  TelemetrySample _mockSample(int nowMs) {
    final heading = _rng.nextDouble() * 360;
    final bpm = 70 + _rng.nextInt(40);
    final mode = ref.read(gamePhaseProvider).name;
    return TelemetrySample(
      tMs: nowMs,
      motion: TelemetryMotion(headingDeg: heading),
      heart: TelemetryHeart(bpm: bpm),
      context: TelemetryContext(mode: mode),
    );
  }
}
