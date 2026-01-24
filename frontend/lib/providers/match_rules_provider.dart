import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatchRulesState {
  final int durationMin;
  final String mapName;
  final int maxPlayers;
  final String releaseMode;

  const MatchRulesState({
    required this.durationMin,
    required this.mapName,
    required this.maxPlayers,
    required this.releaseMode,
  });

  MatchRulesState copyWith({
    int? durationMin,
    String? mapName,
    int? maxPlayers,
    String? releaseMode,
  }) {
    return MatchRulesState(
      durationMin: durationMin ?? this.durationMin,
      mapName: mapName ?? this.mapName,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      releaseMode: releaseMode ?? this.releaseMode,
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
      );

  void reset() => state = build();

  void setDurationMin(int v) => state = state.copyWith(durationMin: v);
  void setMapName(String v) => state = state.copyWith(mapName: v);
  void setMaxPlayers(int v) => state = state.copyWith(maxPlayers: v);
  void setReleaseMode(String v) => state = state.copyWith(releaseMode: v);
}
