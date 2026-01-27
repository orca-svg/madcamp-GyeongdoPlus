import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_phase_provider.dart';

/// 앱의 현재 활성 탭 상태 (워치 미러링의 single source of truth)
enum ActiveTab {
  // OFF_GAME
  offgameHome,
  offgameRecent,
  offgameProfile,
  // LOBBY
  lobbyMain,
  // IN_GAME
  ingameRadar,
  ingameMap,
  ingameCapture,
  ingameSettings,
  // POST_GAME
  postgameSummary,
}

extension ActiveTabExt on ActiveTab {
  /// Wire string for watch communication
  String get wire {
    switch (this) {
      case ActiveTab.offgameHome:
        return 'OFFGAME_HOME';
      case ActiveTab.offgameRecent:
        return 'OFFGAME_RECENT';
      case ActiveTab.offgameProfile:
        return 'OFFGAME_PROFILE';
      case ActiveTab.lobbyMain:
        return 'LOBBY_MAIN';
      case ActiveTab.ingameRadar:
        return 'INGAME_RADAR';
      case ActiveTab.ingameMap:
        return 'INGAME_MAP';
      case ActiveTab.ingameCapture:
        return 'INGAME_CAPTURE';
      case ActiveTab.ingameSettings:
        return 'INGAME_SETTINGS';
      case ActiveTab.postgameSummary:
        return 'POSTGAME_SUMMARY';
    }
  }

  /// Phase this tab belongs to
  GamePhase get phase {
    switch (this) {
      case ActiveTab.offgameHome:
      case ActiveTab.offgameRecent:
      case ActiveTab.offgameProfile:
        return GamePhase.offGame;
      case ActiveTab.lobbyMain:
        return GamePhase.lobby;
      case ActiveTab.ingameRadar:
      case ActiveTab.ingameMap:
      case ActiveTab.ingameCapture:
      case ActiveTab.ingameSettings:
        return GamePhase.inGame;
      case ActiveTab.postgameSummary:
        return GamePhase.postGame;
    }
  }

  /// Tab index within the phase (for IndexedStack)
  int get indexInPhase {
    switch (this) {
      case ActiveTab.offgameHome:
        return 0;
      case ActiveTab.offgameRecent:
        return 1;
      case ActiveTab.offgameProfile:
        return 2;
      case ActiveTab.lobbyMain:
        return 0;
      case ActiveTab.ingameRadar:
        return 0;
      case ActiveTab.ingameMap:
        return 1;
      case ActiveTab.ingameCapture:
        return 2;
      case ActiveTab.ingameSettings:
        return 3;
      case ActiveTab.postgameSummary:
        return 0;
    }
  }

  /// Parse wire string to ActiveTab
  static ActiveTab? fromWire(String wire) {
    switch (wire.toUpperCase()) {
      case 'OFFGAME_HOME':
        return ActiveTab.offgameHome;
      case 'OFFGAME_RECENT':
        return ActiveTab.offgameRecent;
      case 'OFFGAME_PROFILE':
        return ActiveTab.offgameProfile;
      case 'LOBBY_MAIN':
        return ActiveTab.lobbyMain;
      case 'INGAME_RADAR':
        return ActiveTab.ingameRadar;
      case 'INGAME_MAP':
        return ActiveTab.ingameMap;
      case 'INGAME_CAPTURE':
        return ActiveTab.ingameCapture;
      case 'INGAME_SETTINGS':
        return ActiveTab.ingameSettings;
      case 'POSTGAME_SUMMARY':
        return ActiveTab.postgameSummary;
      default:
        return null;
    }
  }

  /// Get default tab for a phase
  static ActiveTab defaultForPhase(GamePhase phase) {
    switch (phase) {
      case GamePhase.offGame:
        return ActiveTab.offgameHome;
      case GamePhase.lobby:
        return ActiveTab.lobbyMain;
      case GamePhase.inGame:
        return ActiveTab.ingameRadar;
      case GamePhase.postGame:
        return ActiveTab.postgameSummary;
    }
  }

  /// Get tab from phase and index
  static ActiveTab fromPhaseAndIndex(GamePhase phase, int index) {
    switch (phase) {
      case GamePhase.offGame:
        switch (index) {
          case 0:
            return ActiveTab.offgameHome;
          case 1:
            return ActiveTab.offgameRecent;
          case 2:
            return ActiveTab.offgameProfile;
          default:
            return ActiveTab.offgameHome;
        }
      case GamePhase.lobby:
        return ActiveTab.lobbyMain;
      case GamePhase.inGame:
        switch (index) {
          case 0:
            return ActiveTab.ingameRadar;
          case 1:
            return ActiveTab.ingameMap;
          case 2:
            return ActiveTab.ingameCapture;
          case 3:
            return ActiveTab.ingameSettings;
          default:
            return ActiveTab.ingameRadar;
        }
      case GamePhase.postGame:
        return ActiveTab.postgameSummary;
    }
  }
}

final activeTabProvider = NotifierProvider<ActiveTabController, ActiveTab>(
  ActiveTabController.new,
);

class ActiveTabController extends Notifier<ActiveTab> {
  @override
  ActiveTab build() => ActiveTab.offgameHome;

  void setTab(ActiveTab tab) => state = tab;

  void setFromWire(String wire) {
    final tab = ActiveTabExt.fromWire(wire);
    if (tab != null) state = tab;
  }

  void setFromPhaseAndIndex(GamePhase phase, int index) {
    state = ActiveTabExt.fromPhaseAndIndex(phase, index);
  }

  /// Reset to default tab when phase changes
  void resetToPhaseDefault(GamePhase phase) {
    state = ActiveTabExt.defaultForPhase(phase);
  }
}

/// Computed wire string for current active tab
final activeTabWireProvider = Provider<String>((ref) {
  return ref.watch(activeTabProvider).wire;
});
