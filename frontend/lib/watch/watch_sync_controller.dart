import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/providers/ability_provider.dart';
import '../providers/active_tab_provider.dart';
import '../providers/game_phase_provider.dart';
import '../providers/watch_provider.dart';
import '../providers/room_provider.dart';
import '../providers/match_rules_provider.dart';
import '../services/watch_sync_service.dart';
import 'state_snapshot_builder.dart';
import 'watch_debug_overrides.dart';

class WatchSyncState {
  final GamePhase phase;
  final int lastSnapshotTs;
  final int lastHapticTs;
  final int? currentHeartRate;

  const WatchSyncState({
    required this.phase,
    required this.lastSnapshotTs,
    required this.lastHapticTs,
    this.currentHeartRate,
  });

  factory WatchSyncState.initial(GamePhase phase) =>
      WatchSyncState(phase: phase, lastSnapshotTs: 0, lastHapticTs: 0);

  WatchSyncState copyWith({
    GamePhase? phase,
    int? lastSnapshotTs,
    int? lastHapticTs,
    int? currentHeartRate,
  }) {
    return WatchSyncState(
      phase: phase ?? this.phase,
      lastSnapshotTs: lastSnapshotTs ?? this.lastSnapshotTs,
      lastHapticTs: lastHapticTs ?? this.lastHapticTs,
      currentHeartRate: currentHeartRate ?? this.currentHeartRate,
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

    // Watch Service init & Listen
    final service = ref.read(watchSyncServiceProvider);

    final sub = service.actionStream.listen((msg) {
      final payload = msg['payload'] as Map<String, dynamic>?;
      if (payload != null && payload['action'] == 'HEART_RATE') {
        final val = payload['value'];
        if (val is int) {
          state = state.copyWith(currentHeartRate: val);
        } else if (val is double) {
          state = state.copyWith(currentHeartRate: val.round());
        }
      } else if (payload != null && payload['action'] == 'USE_SKILL') {
        ref.read(abilityProvider.notifier).useSkill();
      }
    });
    ref.onDispose(sub.cancel);

    // Init Native
    Future.microtask(() async {
      await service.init();
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

    // watch 연결이 true로 바뀌는 순간 즉시 1회 전송
    ref.listen<bool>(watchConnectedProvider, (prev, next) {
      if (next == true) {
        _sendSnapshot();
      }
    });

    // activeTab 변경 시 즉시 전송
    ref.listen<ActiveTab>(activeTabProvider, (prev, next) {
      _sendSnapshot();
    });

    // Room 상태 변경 시(팀 변경 등) 즉시 전송
    ref.listen<RoomState>(roomProvider, (prev, next) {
      if (prev?.me?.team != next.me?.team) {
        _sendSnapshot();
      }
    });

    // Ability 변경 시 즉시 전송 (쿨타임 등)
    ref.listen<AbilityState>(abilityProvider, (prev, next) {
      if (prev?.cooldownRemainSec != next.cooldownRemainSec ||
          prev?.isReady != next.isReady) {
        _sendSnapshot();
      }
    });

    // Rules 변경 시 즉시 전송 (시간, 모드 등)
    ref.listen<MatchRulesState>(matchRulesProvider, (prev, next) {
      // 규칙 변경은 중요하므로 변경 시 항상 전송
      _sendSnapshot();
    });

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

    // Inject Ability State
    final ability = ref.read(abilityProvider);
    if (snapshot['payload'] is Map && snapshot['payload']['my'] is Map) {
      final my = snapshot['payload']['my'] as Map<String, dynamic>;
      my['skill'] = {
        'type': ability.type.name,
        'label': ability.type.label,
        'sf': ability.type.sfSymbol,
        'remain': ability.cooldownRemainSec,
        'total': ability.totalCooldownSec,
        'ready': ability.isReady,
      };
    }

    await ref.read(watchSyncServiceProvider).sendStateSnapshot(snapshot);
    final len = jsonEncode(snapshot).length;
    final matchId = snapshot['matchId'];
    // debugPrint('[WATCH][FLUTTER][TX] STATE_SNAPSHOT matchId=$matchId len=$len');

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

    if (team != 'THIEF' || !enemyNear) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - state.lastHapticTs < _enemyCooldownMs) return;

    final haptic = {
      'type': 'HAPTIC_ALERT',
      'ts': now,
      'matchId': snapshot['matchId'],
      'payload': {'kind': 'ENEMY_NEAR_5M', 'cooldownSec': 5, 'durationMs': 300},
    };
    await ref.read(watchSyncServiceProvider).sendHapticAlert(haptic);
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
