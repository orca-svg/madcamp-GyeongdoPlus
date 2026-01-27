import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/active_tab_provider.dart';
import '../providers/game_phase_provider.dart';
import '../providers/watch_provider.dart';
import 'state_snapshot_builder.dart';
import 'watch_bridge.dart';
import 'watch_debug_overrides.dart';

class WatchSyncState {
  final GamePhase phase;
  final int lastSnapshotTs;
  final int lastHapticTs;

  const WatchSyncState({
    required this.phase,
    required this.lastSnapshotTs,
    required this.lastHapticTs,
  });

  factory WatchSyncState.initial(GamePhase phase) =>
      WatchSyncState(phase: phase, lastSnapshotTs: 0, lastHapticTs: 0);

  WatchSyncState copyWith({
    GamePhase? phase,
    int? lastSnapshotTs,
    int? lastHapticTs,
  }) {
    return WatchSyncState(
      phase: phase ?? this.phase,
      lastSnapshotTs: lastSnapshotTs ?? this.lastSnapshotTs,
      lastHapticTs: lastHapticTs ?? this.lastHapticTs,
    );
  }
}

final watchSyncControllerProvider =
    NotifierProvider<WatchSyncController, WatchSyncState>(
      WatchSyncController.new,
    );

class WatchSyncController extends Notifier<WatchSyncState> {
  Timer? _snapshotTimer;
  Timer? _enemyTimer;

  static const _enemyCheckInterval = Duration(seconds: 5);
  static const int _enemyCooldownMs = 5000;

  @override
  WatchSyncState build() {
    ref.onDispose(_disposeTimers);

    final phase = effectiveWatchPhase((p) => ref.read(p));
    state = WatchSyncState.initial(phase);

    // watch 초기화 (1회)
    Future.microtask(() async {
      await ref.read(watchConnectedProvider.notifier).init();
    });

    // phase 변경 시 주기 재스케줄
    ref.listen<GamePhase>(gamePhaseProvider, (prev, next) {
      final override = kDebugMode
          ? ref.read(debugWatchPhaseOverrideProvider)
          : null;
      if (override != null) return;
      _scheduleForPhase(next);
      state = state.copyWith(phase: next);
    });

    // Debug override 변경 시에도 재스케줄
    ref.listen<GamePhase?>(debugWatchPhaseOverrideProvider, (prev, next) {
      if (!kDebugMode) return;
      final GamePhase effective = next ?? ref.read(gamePhaseProvider);
      _scheduleForPhase(effective);
      state = state.copyWith(phase: effective);
    });

    // watch 연결이 true로 바뀌는 순간 즉시 1회 전송(“연결됐는데 5초 기다리는” UX 방지)
    ref.listen<bool>(watchConnectedProvider, (prev, next) {
      if (next == true) {
        _sendSnapshot();
      }
    });

    // activeTab 변경 시 즉시 전송 (탭 미러링)
    ref.listen<ActiveTab>(activeTabProvider, (prev, next) {
      _sendSnapshot();
    });

    // 초기 스케줄 + 즉시 1회 전송
    _scheduleForPhase(phase);
    _sendSnapshot();

    return state;
  }

  void _scheduleForPhase(GamePhase phase) {
    _snapshotTimer?.cancel();
    _enemyTimer?.cancel();

    final period = _snapshotPeriodForPhase(phase);

    _snapshotTimer = Timer.periodic(period, (_) {
      _sendSnapshot();
    });

    // enemy check는 IN_GAME에서만 5초 주기로 수행
    if (phase == GamePhase.inGame) {
      _enemyTimer = Timer.periodic(_enemyCheckInterval, (_) {
        _checkEnemyNear();
      });
    }
  }

  Duration _snapshotPeriodForPhase(GamePhase phase) {
    switch (phase) {
      case GamePhase.offGame:
        return const Duration(seconds: 5);
      case GamePhase.lobby:
        return const Duration(seconds: 2);
      case GamePhase.inGame:
        return const Duration(seconds: 3);
      case GamePhase.postGame:
        return const Duration(seconds: 5);
    }
  }

  Future<void> _sendSnapshot() async {
    final connected = ref.read(watchConnectedProvider);
    if (!connected) return;

    final snapshot = StateSnapshotBuilder.build((p) => ref.read(p));
    await ref.read(watchBridgeProvider).sendStateSnapshot(snapshot);
    final len = jsonEncode(snapshot).length;
    final matchId = snapshot['matchId'];
    debugPrint('[WATCH][FLUTTER][TX] STATE_SNAPSHOT matchId=$matchId len=$len');

    state = state.copyWith(
      lastSnapshotTs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _checkEnemyNear() async {
    final connected = ref.read(watchConnectedProvider);
    if (!connected) return;

    final snapshot = StateSnapshotBuilder.build((p) => ref.read(p));
    final payload = snapshot['payload'] as Map<String, dynamic>? ?? {};
    final team = payload['team']?.toString() ?? 'UNKNOWN';
    final nearby = payload['nearby'] as Map<String, dynamic>? ?? {};
    final enemyNear = nearby['enemyNear'] == true;

    // 도둑 + 적 근접일 때만
    if (team != 'THIEF' || !enemyNear) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // 쿨다운(5초) 강제
    if (now - state.lastHapticTs < _enemyCooldownMs) return;

    final haptic = {
      'type': 'HAPTIC_ALERT',
      'ts': now,
      'matchId': snapshot['matchId'],
      'payload': {'kind': 'ENEMY_NEAR_5M', 'cooldownSec': 5, 'durationMs': 300},
    };
    await ref.read(watchBridgeProvider).sendHapticAlert(haptic);
    final len = jsonEncode(haptic).length;
    final matchId = haptic['matchId'];
    debugPrint('[WATCH][FLUTTER][TX] HAPTIC_ALERT matchId=$matchId len=$len');

    state = state.copyWith(lastHapticTs: now);
  }

  void _disposeTimers() {
    _snapshotTimer?.cancel();
    _enemyTimer?.cancel();
    _snapshotTimer = null;
    _enemyTimer = null;
  }
}
