import 'package:flutter_riverpod/flutter_riverpod.dart';

enum GamePhase { offGame, lobby, inGame, postGame }

final gamePhaseProvider = NotifierProvider<GamePhaseController, GamePhase>(GamePhaseController.new);

class GamePhaseController extends Notifier<GamePhase> {
  @override
  GamePhase build() => GamePhase.offGame;

  void setPhase(GamePhase p) => state = p;

  void toOffGame() => state = GamePhase.offGame;
  void toLobby() => state = GamePhase.lobby;
  void toInGame() => state = GamePhase.inGame;
  void toPostGame() => state = GamePhase.postGame;
}

