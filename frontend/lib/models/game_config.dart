enum GameMode {
  normal,
  item,
  ability;

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

  String get wireName => name.toUpperCase();

  static GameMode fromWire(String? value) {
    switch (value?.toUpperCase()) {
      case 'ITEM':
        return GameMode.item;
      case 'ABILITY':
        return GameMode.ability;
      default:
        return GameMode.normal;
    }
  }
}

class GameConfig {
  final GameMode gameMode;
  final int durationMin;
  final bool jailEnabled;

  const GameConfig({
    required this.gameMode,
    required this.durationMin,
    required this.jailEnabled,
  });

  factory GameConfig.initial() {
    return const GameConfig(
      gameMode: GameMode.normal,
      durationMin: 10,
      jailEnabled: true,
    );
  }

  GameConfig copyWith({
    GameMode? gameMode,
    int? durationMin,
    bool? jailEnabled,
  }) {
    return GameConfig(
      gameMode: gameMode ?? this.gameMode,
      durationMin: durationMin ?? this.durationMin,
      jailEnabled: jailEnabled ?? this.jailEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameMode': gameMode.wireName,
      'durationMin': durationMin,
      'jailEnabled': jailEnabled,
    };
  }

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      gameMode: GameMode.fromWire(json['gameMode'] as String?),
      durationMin: (json['durationMin'] as num?)?.toInt() ?? 10,
      jailEnabled: json['jailEnabled'] as bool? ?? true,
    );
  }

  @override
  String toString() =>
      'GameConfig(mode=${gameMode.label}, time=${durationMin}m, jail=$jailEnabled)';
}
