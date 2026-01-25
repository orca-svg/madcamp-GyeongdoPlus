import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 게임 모드 enum
enum GameMode {
  normal,
  item,
  ability;

  /// 서버 전송용 문자열 (NORMAL, ITEM, ABILITY)
  String get wire {
    switch (this) {
      case GameMode.normal:
        return 'NORMAL';
      case GameMode.item:
        return 'ITEM';
      case GameMode.ability:
        return 'ABILITY';
    }
  }

  /// UI 표시용 한글 라벨
  String get label {
    switch (this) {
      case GameMode.normal:
        return '일반';
      case GameMode.item:
        return '아이템';
      case GameMode.ability:
        return '능력';
    }
  }

  /// 서버 문자열에서 GameMode로 변환
  static GameMode fromWire(String? wire) {
    switch (wire?.toUpperCase()) {
      case 'ITEM':
        return GameMode.item;
      case 'ABILITY':
        return GameMode.ability;
      default:
        return GameMode.normal;
    }
  }
}

class MatchRulesState {
  final int durationMin;
  final String mapName;
  final int maxPlayers;
  final String releaseMode;
  final GameMode gameMode;

  const MatchRulesState({
    required this.durationMin,
    required this.mapName,
    required this.maxPlayers,
    required this.releaseMode,
    required this.gameMode,
  });

  MatchRulesState copyWith({
    int? durationMin,
    String? mapName,
    int? maxPlayers,
    String? releaseMode,
    GameMode? gameMode,
  }) {
    return MatchRulesState(
      durationMin: durationMin ?? this.durationMin,
      mapName: mapName ?? this.mapName,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      releaseMode: releaseMode ?? this.releaseMode,
      gameMode: gameMode ?? this.gameMode,
    );
  }
}

final matchRulesProvider = NotifierProvider<MatchRulesController, MatchRulesState>(MatchRulesController.new);

class MatchRulesController extends Notifier<MatchRulesState> {
  @override
  MatchRulesState build() => const MatchRulesState(
        durationMin: 10,
        mapName: '도심',
        maxPlayers: 5,
        releaseMode: '터치/근접',
        gameMode: GameMode.normal,
      );

  void reset() => state = build();

  void setDurationMin(int v) => state = state.copyWith(durationMin: v);
  void setMapName(String v) => state = state.copyWith(mapName: v);
  void setMaxPlayers(int v) => state = state.copyWith(maxPlayers: v);
  void setReleaseMode(String v) => state = state.copyWith(releaseMode: v);
  void setGameMode(GameMode v) => state = state.copyWith(gameMode: v);
}
