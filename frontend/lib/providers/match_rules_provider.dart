import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeoPointDto {
  final double lat;
  final double lng;

  const GeoPointDto({required this.lat, required this.lng});

  GeoPointDto copyWith({double? lat, double? lng}) {
    return GeoPointDto(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  GeoPointDto clamp() {
    return GeoPointDto(
      lat: lat.clamp(-90.0, 90.0),
      lng: lng.clamp(-180.0, 180.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat.clamp(-90.0, 90.0),
        'lng': lng.clamp(-180.0, 180.0),
      };

  factory GeoPointDto.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (json['lng'] as num?)?.toDouble() ?? 0.0;
    return GeoPointDto(lat: lat, lng: lng).clamp();
  }
}

extension GeoPolygonKakaoLikeX on List<GeoPointDto> {
  /// Step 5-2에서 KakaoMap 플러그인의 LatLng 타입으로 변환할 때 사용.
  /// (5-1 단계에서는 플러그인 import 없이 계약만 확정)
  List<Map<String, double>> toKakaoLatLngLike() => [
        for (final p in this) {'lat': p.lat.clamp(-90.0, 90.0), 'lng': p.lng.clamp(-180.0, 180.0)},
      ];
}

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
  final List<GeoPointDto>? zonePolygon;

  const MatchRulesState({
    required this.durationMin,
    required this.mapName,
    required this.maxPlayers,
    required this.releaseMode,
    required this.gameMode,
    required this.zonePolygon,
  });

  MatchRulesState copyWith({
    int? durationMin,
    String? mapName,
    int? maxPlayers,
    String? releaseMode,
    GameMode? gameMode,
    List<GeoPointDto>? zonePolygon,
  }) {
    return MatchRulesState(
      durationMin: durationMin ?? this.durationMin,
      mapName: mapName ?? this.mapName,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      releaseMode: releaseMode ?? this.releaseMode,
      gameMode: gameMode ?? this.gameMode,
      zonePolygon: zonePolygon ?? this.zonePolygon,
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
        zonePolygon: null,
      );

  void reset() => state = build();

  void setDurationMin(int v) => state = state.copyWith(durationMin: v);
  void setMapName(String v) => state = state.copyWith(mapName: v);
  void setMaxPlayers(int v) => state = state.copyWith(maxPlayers: v);
  void setReleaseMode(String v) => state = state.copyWith(releaseMode: v);
  void setGameMode(GameMode v) => state = state.copyWith(gameMode: v);
  void setZonePolygon(List<GeoPointDto>? polygon) {
    if (polygon == null) {
      state = state.copyWith(zonePolygon: null);
      return;
    }
    final clamped = polygon.map((p) => p.clamp()).toList(growable: false);
    state = state.copyWith(zonePolygon: clamped);
  }
}
