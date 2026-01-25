import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/haptics/haptics.dart';
import '../net/ws/dto/match_state.dart';
import '../net/ws/dto/radar_ping.dart';
import '../net/ws/ws_envelope.dart';
import '../net/ws/ws_types.dart';
import 'game_phase_provider.dart';
import '../watch/watch_bridge.dart';

class MatchSyncState {
  final WsEnvelope<MatchStateDto>? lastMatchState;
  final WsEnvelope<RadarPingPayload>? lastRadarPing;
  final String? lastJsonPreview;
  final int? lastSeq;
  final String? currentMatchId;

  const MatchSyncState({
    required this.lastMatchState,
    required this.lastRadarPing,
    required this.lastJsonPreview,
    required this.lastSeq,
    required this.currentMatchId,
  });

  factory MatchSyncState.initial() => const MatchSyncState(
        lastMatchState: null,
        lastRadarPing: null,
        lastJsonPreview: null,
        lastSeq: null,
        currentMatchId: null,
      );

  MatchSyncState copyWith({
    WsEnvelope<MatchStateDto>? lastMatchState,
    WsEnvelope<RadarPingPayload>? lastRadarPing,
    String? lastJsonPreview,
    int? lastSeq,
    String? currentMatchId,
  }) {
    return MatchSyncState(
      lastMatchState: lastMatchState ?? this.lastMatchState,
      lastRadarPing: lastRadarPing ?? this.lastRadarPing,
      lastJsonPreview: lastJsonPreview ?? this.lastJsonPreview,
      lastSeq: lastSeq ?? this.lastSeq,
      currentMatchId: currentMatchId ?? this.currentMatchId,
    );
  }
}

final matchSyncProvider = NotifierProvider<MatchSyncController, MatchSyncState>(MatchSyncController.new);

class MatchSyncController extends Notifier<MatchSyncState> {
  final Map<String, int> _cooldownUntilMs = {};
  String? _capture95MatchId;

  @override
  MatchSyncState build() => MatchSyncState.initial();

  void setCurrentMatchId(String matchId) => state = state.copyWith(currentMatchId: matchId);

  void clearSnapshot() {
    state = state.copyWith(
      lastMatchState: null,
      lastRadarPing: null,
      lastJsonPreview: null,
    );
  }

  void setMatchState(WsEnvelope<MatchStateDto> env) {
    _maybeCapture95(env.payload);
    state = state.copyWith(
      lastMatchState: env,
      lastJsonPreview: jsonEncode(env.toJson((p) => p.toJson())),
      currentMatchId: env.payload.matchId,
    );

    if (env.payload.state == 'ENDED') {
      ref.read(gamePhaseProvider.notifier).toPostGame();
    }
  }

  void setRadarPing(WsEnvelope<RadarPingPayload> env) {
    _maybeEnemyPing(env.payload);
    state = state.copyWith(
      lastRadarPing: env,
      lastJsonPreview: jsonEncode(env.toJson((p) => p.toJson())),
    );
  }

  void clearPreview() => state = state.copyWith(lastJsonPreview: '');

  bool applyEnvelope(WsEnvelope<Object?> env) {
    final gap = _updateSeq(env.seq);

    switch (env.type) {
      case WsType.matchState:
        if (env.payload is Map) {
          final dto = MatchStateDto.fromJson((env.payload as Map).cast<String, dynamic>());
          setMatchState(
            WsEnvelope<MatchStateDto>(
              v: env.v,
              type: env.type,
              payload: dto,
              matchId: env.matchId,
              seq: env.seq,
              ts: env.ts,
            ),
          );
        } else {
          _previewRaw(env);
        }
        break;
      case WsType.radarPing:
        if (env.payload is Map) {
          final dto = RadarPingPayload.fromJson((env.payload as Map).cast<String, dynamic>());
          setRadarPing(
            WsEnvelope<RadarPingPayload>(
              v: env.v,
              type: env.type,
              payload: dto,
              matchId: env.matchId,
              seq: env.seq,
              ts: env.ts,
            ),
          );
        } else {
          _previewRaw(env);
        }
        break;
      case WsType.matchEvent:
        _previewRaw(env);
        _maybeMatchEventHaptics(env.payload);
        break;
      case WsType.error:
        _previewRaw(env);
        _hapticIfAllowed('error', const Duration(seconds: 3), HapticPattern.warning, watchType: 'warning');
        break;
      default:
        _previewRaw(env);
        break;
    }

    return gap;
  }

  bool _updateSeq(int? seq) {
    if (seq == null) return false;
    final prev = state.lastSeq;
    final gap = prev != null && seq != (prev + 1);
    state = state.copyWith(lastSeq: seq);
    return gap;
  }

  void _previewRaw(WsEnvelope<Object?> env) {
    Map<String, dynamic> payloadToJson(Object? p) {
      if (p is Map) return p.cast<String, dynamic>();
      return {'value': p};
    }

    state = state.copyWith(lastJsonPreview: jsonEncode(env.toJson(payloadToJson)));
  }

  void _maybeEnemyPing(RadarPingPayload payload) {
    final hasEnemy = payload.pings.any((p) {
      final k = p.kind.toUpperCase();
      return k.contains('ENEMY') || k.contains('THIEF');
    });
    if (!hasEnemy) return;

    final cooldown = Duration(milliseconds: payload.ttlMs.clamp(3000, 20000));
    _hapticIfAllowed('enemy_ping', cooldown, HapticPattern.enemyPing, watchType: 'warning');
  }

  void _maybeCapture95(MatchStateDto s) {
    final mid = s.matchId;
    if (_capture95MatchId != mid) _capture95MatchId = null;

    final p = s.live.captureProgress?.progress01;
    if (p == null) return;
    if (p < 0.95) return;
    if (_capture95MatchId == mid) return;
    _capture95MatchId = mid;

    _hapticIfAllowed('capture95', const Duration(seconds: 3), HapticPattern.captureNearlyDone, watchType: 'warning');
  }

  void _maybeMatchEventHaptics(Object? payload) {
    if (payload is! Map) return;
    final m = payload.cast<String, dynamic>();
    final event = (m['event'] ?? '').toString();
    if (event == 'CAPTURE_CONFIRMED') {
      _hapticIfAllowed('capture_confirmed', const Duration(seconds: 3), HapticPattern.captureConfirmed, watchType: 'failure');
      return;
    }
    if (event == 'RESCUE_RESULT') {
      final result = (m['result'] ?? '').toString();
      if (result == 'SUCCESS') {
        _hapticIfAllowed('rescue_success', const Duration(seconds: 3), HapticPattern.rescueSuccess, watchType: 'success');
      }
      return;
    }
  }

  void _hapticIfAllowed(
    String key,
    Duration cooldown,
    HapticPattern pattern, {
    required String watchType,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final until = _cooldownUntilMs[key] ?? 0;
    if (now < until) return;
    _cooldownUntilMs[key] = now + cooldown.inMilliseconds;

    Haptics.pattern(pattern);
    WatchBridge.sendHaptic(type: watchType);
  }
}
