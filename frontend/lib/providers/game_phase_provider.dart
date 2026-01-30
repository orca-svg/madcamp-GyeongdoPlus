import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GamePhase { offGame, lobby, inGame, postGame }

final gamePhaseProvider = NotifierProvider<GamePhaseController, GamePhase>(GamePhaseController.new);

class GamePhaseController extends Notifier<GamePhase> {
  @override
  GamePhase build() => GamePhase.offGame;

  /// Valid phase transitions:
  /// offGame -> lobby (join/create room)
  /// lobby -> inGame (game starts)
  /// inGame -> postGame (game ends)
  /// postGame -> offGame (leave results)
  /// Any -> offGame (force exit)
  void setPhase(GamePhase p) {
    if (!_isValidTransition(state, p)) {
      print('[GamePhase] Warning: Invalid transition ${state.name} -> ${p.name}');
    }
    state = p;
  }

  void toOffGame() => state = GamePhase.offGame;

  void toLobby() {
    if (state != GamePhase.offGame && state != GamePhase.postGame) {
      print('[GamePhase] Warning: toLobby() called from ${state.name}');
    }
    state = GamePhase.lobby;
  }

  void toInGame() {
    if (state != GamePhase.lobby) {
      print('[GamePhase] Warning: toInGame() called from ${state.name}');
    }
    state = GamePhase.inGame;
  }

  void toPostGame() {
    if (state != GamePhase.inGame) {
      print('[GamePhase] Warning: toPostGame() called from ${state.name}');
    }
    state = GamePhase.postGame;
  }

  bool _isValidTransition(GamePhase from, GamePhase to) {
    // Can always force exit to offGame
    if (to == GamePhase.offGame) return true;

    switch (from) {
      case GamePhase.offGame:
        return to == GamePhase.lobby;
      case GamePhase.lobby:
        return to == GamePhase.inGame || to == GamePhase.offGame;
      case GamePhase.inGame:
        return to == GamePhase.postGame || to == GamePhase.offGame;
      case GamePhase.postGame:
        return to == GamePhase.offGame || to == GamePhase.lobby;
    }
  }
}

