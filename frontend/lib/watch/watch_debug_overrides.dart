import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/game_phase_provider.dart';

typedef ProviderRead = dynamic Function(dynamic provider);

final debugWatchPhaseOverrideProvider =
    NotifierProvider<DebugWatchPhaseOverride, GamePhase?>(
  DebugWatchPhaseOverride.new,
);

class DebugWatchPhaseOverride extends Notifier<GamePhase?> {
  @override
  GamePhase? build() => null;

  void set(GamePhase? phase) => state = phase;
}

GamePhase effectiveWatchPhase(ProviderRead read) {
  if (!kDebugMode) return read(gamePhaseProvider);
  final override = read(debugWatchPhaseOverrideProvider);
  return override ?? read(gamePhaseProvider);
}
