import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/game_provider.dart';

/// List of high heart rate targets for Chaser ability
class ChaserTargetsController extends Notifier<List<PlayerState>> {
  @override
  List<PlayerState> build() {
    return [];
  }

  void updateTargets(List<PlayerState> targets) {
    state = targets;
  }

  void clear() {
    state = [];
  }
}

final chaserTargetsProvider =
    NotifierProvider<ChaserTargetsController, List<PlayerState>>(
  ChaserTargetsController.new,
);
