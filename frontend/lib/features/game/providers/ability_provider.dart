import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart'; // For IconData, Icons
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../providers/game_phase_provider.dart';
import '../../../../core/services/audio_service.dart'; // Audio
import '../../../../providers/game_provider.dart';
import '../../../../providers/room_provider.dart';
import '../../../../providers/app_providers.dart'; // gameRepositoryProvider
import '../../../../data/dto/game_dto.dart'; // UseAbilityDto
import 'chaser_targets_provider.dart';
// import '../game_screen.dart'; // Circular dependency if not careful, used for types? No.

enum AbilityType {
  // Police
  chaser(label: '추격자', sfSymbol: 'figure.run', defaultCooldown: 120),
  scanner(label: '탐지자', sfSymbol: 'waveform.path.ecg', defaultCooldown: 90),
  jailkeeper(label: '감옥지기', sfSymbol: 'lock.shield', defaultCooldown: 180),
  silencer(label: '집행자', sfSymbol: 'speaker.slash', defaultCooldown: 150),

  // Thief
  shadow(label: '그림자', sfSymbol: 'cloud.fog', defaultCooldown: 120),
  clown(label: '광대', sfSymbol: 'theatermasks', defaultCooldown: 100),
  hacker(label: '해커', sfSymbol: 'laptopcomputer', defaultCooldown: 140),
  broker(label: '브로커', sfSymbol: 'banknote', defaultCooldown: 160),

  none(label: '없음', sfSymbol: 'xmark', defaultCooldown: 0);

  final String label;
  final String sfSymbol;
  final int defaultCooldown; // Seconds

  const AbilityType({
    required this.label,
    required this.sfSymbol,
    required this.defaultCooldown,
  });

  bool get isPolice => index <= 3;
  bool get isThief => index >= 4 && index <= 7;

  String get wireClass {
    switch (this) {
      case AbilityType.chaser:
        return 'CHASER';
      case AbilityType.scanner:
        return 'SEARCHER';
      case AbilityType.jailkeeper:
        return 'JAILER';
      case AbilityType.silencer:
        return 'ENFORCER';
      case AbilityType.shadow:
        return 'SHADOW';
      case AbilityType.clown:
        return 'CLOWN';
      case AbilityType.hacker:
        return 'HACKER';
      case AbilityType.broker:
        return 'BROKER';
      case AbilityType.none:
        return '';
    }
  }

  IconData get icon {
    switch (this) {
      case AbilityType.chaser:
        return Icons.directions_run;
      case AbilityType.scanner:
        return Icons.radar;
      case AbilityType.jailkeeper:
        return Icons.security;
      case AbilityType.silencer:
        return Icons.volume_off;
      case AbilityType.shadow:
        return Icons.cloud;
      case AbilityType.clown:
        return Icons.mood; // Theater masks not standard in Material
      case AbilityType.hacker:
        return Icons.computer;
      case AbilityType.broker:
        return Icons.attach_money;
      case AbilityType.none:
        return Icons.error_outline;
    }
  }
}

class AbilityState {
  final AbilityType type;
  final int cooldownRemainSec;
  final int totalCooldownSec;
  final bool isUsing; // Duration active
  final int restingHeartRate;
  final int currentHeartRate;
  final double cooldownSpeed; // Debug info
  final double clownGauge; // Clown ability gauge (0.0 ~ 1.0)

  const AbilityState({
    required this.type,
    required this.cooldownRemainSec,
    required this.totalCooldownSec,
    this.isUsing = false,
    this.restingHeartRate = 70,
    this.currentHeartRate = 70,
    this.cooldownSpeed = 1.0,
    this.clownGauge = 0.0,
  });

  bool get isReady => cooldownRemainSec <= 0 && type != AbilityType.none;
  bool get isSkillActive => isUsing;

  AbilityState copyWith({
    AbilityType? type,
    int? cooldownRemainSec,
    int? totalCooldownSec,
    bool? isUsing,
    int? restingHeartRate,
    int? currentHeartRate,
    double? cooldownSpeed,
    double? clownGauge,
  }) {
    return AbilityState(
      type: type ?? this.type,
      cooldownRemainSec: cooldownRemainSec ?? this.cooldownRemainSec,
      totalCooldownSec: totalCooldownSec ?? this.totalCooldownSec,
      isUsing: isUsing ?? this.isUsing,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      currentHeartRate: currentHeartRate ?? this.currentHeartRate,
      cooldownSpeed: cooldownSpeed ?? this.cooldownSpeed,
      clownGauge: clownGauge ?? this.clownGauge,
    );
  }
}

final abilityProvider = NotifierProvider<AbilityController, AbilityState>(
  AbilityController.new,
);

class AbilityController extends Notifier<AbilityState> {
  Timer? _timer;
  Timer? _chaserPingTimer;
  Timer? _activeTimer;
  // Accumulator for fractional cooldown reduction
  double _accumulator = 0.0;

  @override
  AbilityState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _chaserPingTimer?.cancel();
      _activeTimer?.cancel();
    });

    // Listen to phase to start/stop engine
    ref.listen<GamePhase>(gamePhaseProvider, (prev, next) {
      if (next == GamePhase.inGame) {
        startCooldownEngine();
      } else {
        stopCooldownEngine();
      }
    });

    return const AbilityState(
      type: AbilityType.none,
      cooldownRemainSec: 0,
      totalCooldownSec: 0,
    );
  }

  Future<void> setType(AbilityType type) async {
    state = state.copyWith(
      type: type,
      totalCooldownSec: type.defaultCooldown,
      cooldownRemainSec: 0, // Start ready? or full cooldown? Convention: Ready.
    );

    final room = ref.read(roomProvider);
    if (!room.inRoom || type == AbilityType.none) return;

    try {
      final repo = ref.read(gameRepositoryProvider);
      final result = await repo.selectAbility(
        SelectAbilityDto(matchId: room.roomId, abilityClass: type.wireClass),
      );
      if (!result.success) {
        debugPrint('Ability selection failed on server: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('Ability selection exception: $e');
    }
  }

  void setHeartRate(int bpm) {
    state = state.copyWith(currentHeartRate: bpm);
  }

  void setRestingHeartRate(int bpm) {
    state = state.copyWith(restingHeartRate: bpm);
  }

  /// Called via WatchSyncController/GamePhase timer every second?
  /// Or we run our own timer?
  /// User request: "1초마다 감소하되... 가속 계수 적용"
  /// Using own timer is safer for "engine".
  void startCooldownEngine() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void stopCooldownEngine() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    // Cooldown reduction logic
    if (state.cooldownRemainSec > 0) {
      final diff = state.currentHeartRate - state.restingHeartRate;
      double speed = 1.0;
      if (diff > 20) {
        if (state.type.isPolice) speed = 1.02; // +2%
        if (state.type.isThief) speed = 1.04; // +4%
      }

      // Accumulate
      _accumulator += speed;

      int reduction = 0;
      if (_accumulator >= 1.0) {
        reduction = _accumulator.floor();
        _accumulator -= reduction;
      }

      if (reduction > 0) {
        final next = max(0, state.cooldownRemainSec - reduction);
        state = state.copyWith(cooldownRemainSec: next, cooldownSpeed: speed);
      }
    }

    // Clown gauge logic
    if (state.type == AbilityType.clown && !state.isSkillActive) {
      try {
        final gameState = ref.read(gameProvider);
        final room = ref.read(roomProvider);
        final myPos = gameState.myPosition;
        final myTeam = room.me?.team;

        if (myTeam != Team.thief || myPos == null) {
          return;
        }

        // Check if police within 7m
        final hasNearbyPolice = gameState.players.values.any((player) {
          if (player.team != 'POLICE' || player.isArrested) {
            return false;
          }

          final distance = Geolocator.distanceBetween(
            myPos.latitude,
            myPos.longitude,
            player.lat,
            player.lng,
          );
          return distance < 7.0;
        });

        if (hasNearbyPolice) {
          final newGauge = min(1.0, state.clownGauge + 0.02); // +2% per second
          state = state.copyWith(clownGauge: newGauge);

          // Auto-activate skill when gauge reaches 100%
          if (newGauge >= 1.0) {
            useSkill();
            state = state.copyWith(clownGauge: 0.0); // Reset gauge
          }
        }
      } catch (e) {
        // InteractionService might not be available yet
      }
    }
  }

  Future<void> useSkill() async {
    if (!state.isReady) return;

    // Play SFX
    final repo = ref.read(gameRepositoryProvider);
    final roomId = ref.read(roomProvider).roomId;
    final result = await repo.useAbility(UseAbilityDto(matchId: roomId));
    if (!result.success) {
      debugPrint('Ability usage failed on server: ${result.errorMessage}');
      return;
    }

    ref.read(audioServiceProvider).playSfx(AudioType.abilityActive);

    final response = result.data;
    final data = response?.data;
    final cooldown =
        (data is Map<String, dynamic> ? data['cooldown'] as num? : null)
            ?.toInt() ??
        state.totalCooldownSec;
    final duration =
        (data is Map<String, dynamic> ? data['duration'] as num? : null)
            ?.toInt() ??
        _defaultActiveDuration(state.type);

    _activeTimer?.cancel();
    state = state.copyWith(
      totalCooldownSec: cooldown,
      cooldownRemainSec: cooldown,
      isUsing: duration > 0,
    );

    if (duration > 0) {
      _activeTimer = Timer(Duration(seconds: duration), () {
        if (!ref.mounted) return;
        state = state.copyWith(isUsing: false);
        if (state.type == AbilityType.chaser) {
          stopChaserPing();
        }
      });
    }

    // Ability-specific logic
    if (state.type == AbilityType.chaser && duration > 0) {
      _startChaserPing();
    }
  }

  int _defaultActiveDuration(AbilityType type) {
    switch (type) {
      case AbilityType.scanner:
        return 5;
      case AbilityType.silencer:
        return 5;
      case AbilityType.shadow:
        return 15;
      case AbilityType.hacker:
        return 9;
      case AbilityType.clown:
        return 30;
      case AbilityType.chaser:
        return 10;
      case AbilityType.jailkeeper:
      case AbilityType.broker:
      case AbilityType.none:
        return 0;
    }
  }

  /// Chaser ability: Ping high heart rate targets every 2 seconds
  void _startChaserPing() {
    _chaserPingTimer?.cancel();

    _chaserPingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (state.type != AbilityType.chaser || !state.isSkillActive) {
        stopChaserPing();
        return;
      }

      final gameState = ref.read(gameProvider);

      // Filter thieves with heart rate >= 150 BPM
      final highHrThieves = gameState.players.values.where((p) {
        return p.team == 'THIEF' && (p.heartRate ?? 0) >= 150;
      }).toList();

      // Update chaser targets provider
      ref.read(chaserTargetsProvider.notifier).updateTargets(highHrThieves);
    });
  }

  void stopChaserPing() {
    _chaserPingTimer?.cancel();
    _chaserPingTimer = null;
    ref.read(chaserTargetsProvider.notifier).clear();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _chaserPingTimer?.cancel();
    _chaserPingTimer = null;
    _activeTimer?.cancel();
    _activeTimer = null;
    _accumulator = 0.0;
    ref.read(chaserTargetsProvider.notifier).clear();
    state = const AbilityState(
      type: AbilityType.none,
      cooldownRemainSec: 0,
      totalCooldownSec: 0,
    );
  }
}
