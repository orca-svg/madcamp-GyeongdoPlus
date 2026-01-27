import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/room_provider.dart';

enum AbilityType {
  finder(
    label: '탐지자',
    icon: Icons.radar,
    sfSymbol: 'dot.radiowaves.left.and.right',
    cooldownSec: 30,
    durationSec: 5,
  ),
  jailer(
    label: '감옥지기',
    icon: Icons.lock_clock,
    sfSymbol: 'lock.circle.fill',
    cooldownSec: 30,
    durationSec: 10,
  ),
  executor(
    label: '집행자',
    icon: Icons.gavel,
    sfSymbol: 'exclamationmark.shield.fill',
    cooldownSec: 60,
    durationSec: 10,
  ),
  chaser(
    label: '추격자',
    icon: Icons.directions_run,
    sfSymbol: 'figure.run',
    cooldownSec: 45,
    durationSec: 10,
  ),

  shadow(
    label: '그림자',
    icon: Icons.visibility_off,
    sfSymbol: 'eye.slash.fill',
    cooldownSec: 60,
    durationSec: 30,
  ),
  broker(
    label: '브로커',
    icon: Icons.key,
    sfSymbol: 'key.fill',
    cooldownSec: 90,
    durationSec: 10,
  ),
  hacker(
    label: '해커',
    icon: Icons.wifi_tethering,
    sfSymbol: 'network',
    cooldownSec: 60,
    durationSec: 15,
  ),
  clown(
    label: '광대',
    icon: Icons.face,
    sfSymbol: 'mouth',
    cooldownSec: 120,
    durationSec: 10,
  ),

  none(
    label: '',
    icon: Icons.error,
    sfSymbol: 'questionmark',
    cooldownSec: 0,
    durationSec: 0,
  );

  final String label;
  final IconData icon;
  final String sfSymbol;
  final int cooldownSec;
  final int durationSec;

  const AbilityType({
    required this.label,
    required this.icon,
    required this.sfSymbol,
    required this.cooldownSec,
    required this.durationSec,
  });
}

class AbilityState {
  final AbilityType type;
  final bool isReady;
  final int cooldownRemainSec;
  final int totalCooldownSec;
  final bool isSkillActive;

  const AbilityState({
    required this.type,
    required this.isReady,
    required this.cooldownRemainSec,
    required this.totalCooldownSec,
    required this.isSkillActive,
  });

  factory AbilityState.initial() => const AbilityState(
    type: AbilityType.none,
    isReady: false,
    cooldownRemainSec: 0,
    totalCooldownSec: 1,
    isSkillActive: false,
  );

  AbilityState copyWith({
    AbilityType? type,
    bool? isReady,
    int? cooldownRemainSec,
    int? totalCooldownSec,
    bool? isSkillActive,
  }) {
    return AbilityState(
      type: type ?? this.type,
      isReady: isReady ?? this.isReady,
      cooldownRemainSec: cooldownRemainSec ?? this.cooldownRemainSec,
      totalCooldownSec: totalCooldownSec ?? this.totalCooldownSec,
      isSkillActive: isSkillActive ?? this.isSkillActive,
    );
  }
}

class AbilityController extends Notifier<AbilityState> {
  Timer? _cooldownTimer;
  Timer? _durationTimer;
  bool _initialized = false;

  @override
  AbilityState build() {
    ref.onDispose(() {
      _cooldownTimer?.cancel();
      _durationTimer?.cancel();
    });

    ref.listen(roomProvider, (prev, next) {
      _maybeAutoAssign(next);
    });

    return AbilityState.initial();
  }

  void _maybeAutoAssign(RoomState room) {
    if (_initialized) return;
    if (!room.inRoom) return;

    final team = room.me?.team;
    if (team == null) return;

    _initialized = true;
    final type = (team == Team.police)
        ? AbilityType.finder
        : AbilityType.shadow;
    state = AbilityState(
      type: type,
      isReady: true,
      cooldownRemainSec: 0,
      totalCooldownSec: type.cooldownSec,
      isSkillActive: false,
    );
  }

  void useSkill() {
    if (!state.isReady || state.type == AbilityType.none) return;
    if (state.isSkillActive)
      return; // Already active (shouldn't happen if isReady checked)

    // Activate Skill
    state = state.copyWith(isSkillActive: true);

    // Start Duration Timer
    _durationTimer?.cancel();
    _durationTimer = Timer(Duration(seconds: state.type.durationSec), () {
      state = state.copyWith(isSkillActive: false);
    });

    // Start Cooldown
    _activateCooldown(state.type.cooldownSec);
  }

  void _activateCooldown(int sec) {
    _cooldownTimer?.cancel();
    state = state.copyWith(
      isReady: false,
      cooldownRemainSec: sec,
      totalCooldownSec: sec,
      // isSkillActive preserved (true)
    );
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remain = state.cooldownRemainSec - 1;
      if (remain <= 0) {
        timer.cancel();
        state = state.copyWith(isReady: true, cooldownRemainSec: 0);
      } else {
        state = state.copyWith(cooldownRemainSec: remain);
      }
    });
  }
}

final abilityProvider = NotifierProvider<AbilityController, AbilityState>(
  AbilityController.new,
);
