import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart'; // For IconData, Icons
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/game_phase_provider.dart';
import '../../../../core/services/audio_service.dart'; // Audio
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

  const AbilityState({
    required this.type,
    required this.cooldownRemainSec,
    required this.totalCooldownSec,
    this.isUsing = false,
    this.restingHeartRate = 70,
    this.currentHeartRate = 70,
    this.cooldownSpeed = 1.0,
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
  }) {
    return AbilityState(
      type: type ?? this.type,
      cooldownRemainSec: cooldownRemainSec ?? this.cooldownRemainSec,
      totalCooldownSec: totalCooldownSec ?? this.totalCooldownSec,
      isUsing: isUsing ?? this.isUsing,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      currentHeartRate: currentHeartRate ?? this.currentHeartRate,
      cooldownSpeed: cooldownSpeed ?? this.cooldownSpeed,
    );
  }
}

final abilityProvider = NotifierProvider<AbilityController, AbilityState>(
  AbilityController.new,
);

class AbilityController extends Notifier<AbilityState> {
  Timer? _timer;
  // Accumulator for fractional cooldown reduction
  double _accumulator = 0.0;

  @override
  AbilityState build() {
    ref.onDispose(() {
      _timer?.cancel();
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

  void setType(AbilityType type) {
    state = state.copyWith(
      type: type,
      totalCooldownSec: type.defaultCooldown,
      cooldownRemainSec: 0, // Start ready? or full cooldown? Convention: Ready.
    );
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
    if (state.cooldownRemainSec <= 0) return;

    final diff = state.currentHeartRate - state.restingHeartRate;
    double speed = 1.0;
    if (diff > 20) {
      if (state.type.isPolice) speed = 1.02; // +2%
      if (state.type.isThief) speed = 1.04; // +4%
      // User request: "경찰 1.02배, 도둑 1.04배"
      // Maybe they meant "+0.02 per BPM over 20"? Or flat bonus?
      // "20일 때 가속 계수 적용" usually implies a threshold state.
      // Or continuous? "BPM 100 (diff 30) -> speed?"
      // Let's assume FLAT bonus for being "High HR" based on the phrasing "가속 계수 적용 (경찰 1.02배...)"
      // Actually 1.02x means 2% faster. Over 60s -> 1.2s saved. Minimal.
      // Maybe user meant "per 1 BPM"? Or significantly larger multiplier?
      // "1.02배" is very specific. I'll stick to it.
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

  Future<void> useSkill() async {
    if (!state.isReady) return;

    // Play SFX
    ref.read(audioServiceProvider).playSfx(AudioType.abilityActive);

    // TODO: Call API
    // await _api.useAbility(state.type);
    // For now, optimistic update

    state = state.copyWith(
      cooldownRemainSec: state.totalCooldownSec, // Reset to full
      isUsing: true, // Trigger 'active' state if needed
    );

    // Duration logic? Some skills have duration.
    // For now, just trigger.

    // Haptic feedback via Watch?
    // Done by WatchSyncController hearing 'USE_SKILL' or implicit.
  }
}
