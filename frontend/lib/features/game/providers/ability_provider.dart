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
  ),
  jailer(
    label: '감옥지기',
    icon: Icons.lock_clock,
    sfSymbol: 'lock.circle.fill',
    cooldownSec: 30,
  ),
  executor(
    label: '집행자',
    icon: Icons.gavel,
    sfSymbol: 'exclamationmark.shield.fill',
    cooldownSec: 60,
  ),
  chaser(
    label: '추격자',
    icon: Icons.directions_run,
    sfSymbol: 'figure.run',
    cooldownSec: 45,
  ),

  shadow(
    label: '그림자',
    icon: Icons.visibility_off,
    sfSymbol: 'eye.slash.fill',
    cooldownSec: 60,
  ),
  broker(label: '브로커', icon: Icons.key, sfSymbol: 'key.fill', cooldownSec: 90),
  hacker(
    label: '해커',
    icon: Icons.wifi_tethering,
    sfSymbol: 'network',
    cooldownSec: 60,
  ),
  clown(label: '광대', icon: Icons.face, sfSymbol: 'mouth', cooldownSec: 120),

  none(label: '', icon: Icons.error, sfSymbol: 'questionmark', cooldownSec: 0);

  final String label;
  final IconData icon;
  final String sfSymbol;
  final int cooldownSec;
  const AbilityType({
    required this.label,
    required this.icon,
    required this.sfSymbol,
    required this.cooldownSec,
  });
}

class AbilityState {
  final AbilityType type;
  final bool isReady;
  final int cooldownRemainSec;
  final int totalCooldownSec;

  const AbilityState({
    required this.type,
    required this.isReady,
    required this.cooldownRemainSec,
    required this.totalCooldownSec,
  });

  factory AbilityState.initial() => const AbilityState(
    type: AbilityType.none,
    isReady: false,
    cooldownRemainSec: 0,
    totalCooldownSec: 1,
  );

  AbilityState copyWith({
    AbilityType? type,
    bool? isReady,
    int? cooldownRemainSec,
    int? totalCooldownSec,
  }) {
    return AbilityState(
      type: type ?? this.type,
      isReady: isReady ?? this.isReady,
      cooldownRemainSec: cooldownRemainSec ?? this.cooldownRemainSec,
      totalCooldownSec: totalCooldownSec ?? this.totalCooldownSec,
    );
  }
}

class AbilityController extends Notifier<AbilityState> {
  Timer? _timer;

  @override
  AbilityState build() {
    ref.onDispose(() => _timer?.cancel());
    final room = ref.watch(roomProvider);
    final team = room.me?.team;

    // Auto Assign Logic
    if (room.inRoom && team != null && state.type == AbilityType.none) {
      final type = (team == Team.police)
          ? AbilityType.finder
          : AbilityType.shadow;
      // Default to ready
      return AbilityState(
        type: type,
        isReady: true,
        cooldownRemainSec: 0,
        totalCooldownSec: type.cooldownSec,
      );
    }
    return state;
  }

  void useSkill() {
    if (!state.isReady || state.type == AbilityType.none) return;

    // Start Cooldown
    _activateCooldown(state.type.cooldownSec);
  }

  void _activateCooldown(int sec) {
    _timer?.cancel();
    state = state.copyWith(
      isReady: false,
      cooldownRemainSec: sec,
      totalCooldownSec: sec,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
