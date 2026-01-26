import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeoPointDto {
  final double lat;
  final double lng;

  const GeoPointDto({required this.lat, required this.lng});

  GeoPointDto copyWith({double? lat, double? lng}) {
    return GeoPointDto(lat: lat ?? this.lat, lng: lng ?? this.lng);
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
  /// (플러그인 import 없이 계약만 확정)
  List<Map<String, double>> toKakaoLatLngLike() => [
    for (final p in this)
      {'lat': p.lat.clamp(-90.0, 90.0), 'lng': p.lng.clamp(-180.0, 180.0)},
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
  final int timeLimitSec;
  final String mapName;
  final int maxPlayers;
  final int policeCount;
  final bool policeCountCustomized;
  final String releaseMode;
  final String contactMode;
  final GameMode gameMode;

  /// 구역 폴리곤(최소 3점 권장)
  final List<GeoPointDto>? zonePolygon;

  /// 감옥(원형) 중심/반경
  final bool jailEnabled;
  final GeoPointDto? jailCenter;
  final double? jailRadiusM;

  const MatchRulesState({
    required this.durationMin,
    required this.timeLimitSec,
    required this.mapName,
    required this.maxPlayers,
    required this.policeCount,
    required this.policeCountCustomized,
    required this.releaseMode,
    required this.contactMode,
    required this.gameMode,
    required this.zonePolygon,
    required this.jailEnabled,
    required this.jailCenter,
    required this.jailRadiusM,
  });

  static const Object _unset = Object();

  /// null 세팅도 가능하도록 sentinel 패턴 사용
  MatchRulesState copyWith({
    int? durationMin,
    int? timeLimitSec,
    String? mapName,
    int? maxPlayers,
    int? policeCount,
    bool? policeCountCustomized,
    String? releaseMode,
    String? contactMode,
    GameMode? gameMode,
    Object? zonePolygon = _unset,
    bool? jailEnabled,
    Object? jailCenter = _unset,
    Object? jailRadiusM = _unset,
  }) {
    return MatchRulesState(
      durationMin: durationMin ?? this.durationMin,
      timeLimitSec: timeLimitSec ?? this.timeLimitSec,
      mapName: mapName ?? this.mapName,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      policeCount: policeCount ?? this.policeCount,
      policeCountCustomized:
          policeCountCustomized ?? this.policeCountCustomized,
      releaseMode: releaseMode ?? this.releaseMode,
      contactMode: contactMode ?? this.contactMode,
      gameMode: gameMode ?? this.gameMode,
      zonePolygon: (zonePolygon == _unset)
          ? this.zonePolygon
          : zonePolygon as List<GeoPointDto>?,
      jailEnabled: jailEnabled ?? this.jailEnabled,
      jailCenter: (jailCenter == _unset)
          ? this.jailCenter
          : jailCenter as GeoPointDto?,
      jailRadiusM: (jailRadiusM == _unset)
          ? this.jailRadiusM
          : jailRadiusM as double?,
    );
  }
}

final matchRulesProvider =
    NotifierProvider<MatchRulesController, MatchRulesState>(
      MatchRulesController.new,
    );

class MatchRulesController extends Notifier<MatchRulesState> {
  static const double _minJailRadiusM = 1.0;
  static const double _maxJailRadiusM = 200.0;
  static const double _defaultPoliceRatio = 0.4;

  @override
  MatchRulesState build() => const MatchRulesState(
    durationMin: 10,
    timeLimitSec: 600,
    mapName: '도심',
    maxPlayers: 5,
    policeCount: 2,
    policeCountCustomized: false,
    releaseMode: '터치/근접',
    contactMode: 'NON_CONTACT',
    gameMode: GameMode.normal,
    zonePolygon: null,
    jailEnabled: true,
    jailCenter: null,
    jailRadiusM: null,
  );

  void reset() => state = build();

  void setDurationMin(int v) {
    final min = v.clamp(1, 60);
    state = state.copyWith(durationMin: min, timeLimitSec: min * 60);
  }

  void setTimeLimitSec(int sec) {
    final s = (sec / 60).round() * 60;
    final clamped = s.clamp(300, 1800);
    state = state.copyWith(
      timeLimitSec: clamped,
      durationMin: (clamped / 60).round(),
    );
  }

  void setMapName(String v) => state = state.copyWith(mapName: v);
  void setMaxPlayers(int v) {
    final nextMax = v.clamp(2, 12);
    final nextPolice = _derivePoliceCount(
      maxPlayers: nextMax,
      preferExisting: state.policeCount,
      keepExisting: state.policeCountCustomized,
    );
    state = state.copyWith(maxPlayers: nextMax, policeCount: nextPolice);
  }

  void setPoliceCount(int v) {
    final max = state.maxPlayers;
    final clamped = v.clamp(1, max - 1);
    state = state.copyWith(policeCount: clamped, policeCountCustomized: true);
  }

  void setReleaseMode(String v) => state = state.copyWith(releaseMode: v);
  void setContactMode(String v) => state = state.copyWith(contactMode: v);
  void setGameMode(GameMode v) => state = state.copyWith(gameMode: v);

  void setZonePolygon(List<GeoPointDto>? polygon) {
    if (polygon == null) {
      state = state.copyWith(zonePolygon: null);
      return;
    }
    final clamped = polygon.map((p) => p.clamp()).toList(growable: false);
    state = state.copyWith(zonePolygon: clamped);
  }

  /// center/radius 중 하나라도 유효하지 않으면 둘 다 null 처리(일관성)
  void setJail({GeoPointDto? center, double? radiusM}) {
    final r = (radiusM == null || radiusM <= 0)
        ? null
        : radiusM.clamp(_minJailRadiusM, _maxJailRadiusM).toDouble();
    if (r == null) {
      state = state.copyWith(
        jailEnabled: false,
        jailCenter: null,
        jailRadiusM: null,
      );
      return;
    }

    final c = center?.clamp();
    state = state.copyWith(jailEnabled: true, jailCenter: c, jailRadiusM: r);
  }

  void setJailEnabled(bool enabled) =>
      state = state.copyWith(jailEnabled: enabled);

  /// Offline apply from a draft payload (no WS).
  ///
  /// Expected shape (mapping-friendly):
  /// - mode, maxPlayers, timeLimitSec
  /// - rules.capture.contactMode
  /// - rules.jail.enabled/radiusM/center
  /// - rules.zone.polygon
  void applyOfflineRoomConfig(Map<String, dynamic> payload) {
    final modeRaw = (payload['mode'] ?? '').toString();
    final maxPlayersRaw = payload['maxPlayers'];
    final timeLimitRaw = payload['timeLimitSec'];

    final rules = (payload['rules'] is Map)
        ? (payload['rules'] as Map)
        : const {};
    final capture = (rules['capture'] is Map)
        ? (rules['capture'] as Map)
        : const {};
    final jail = (rules['jail'] is Map) ? (rules['jail'] as Map) : const {};

    final contactRaw = (capture['contactMode'] ?? '').toString();
    final jailEnabledRaw = jail['enabled'];
    final jailRadiusRaw = jail['radiusM'];
    final jailCenterRaw = jail['center'];

    final gm = GameMode.fromWire(modeRaw);
    final mp = (maxPlayersRaw is num)
        ? maxPlayersRaw.toInt()
        : state.maxPlayers;
    final tls = (timeLimitRaw is num)
        ? timeLimitRaw.toInt()
        : state.timeLimitSec;

    final cm = contactRaw.isEmpty ? state.contactMode : contactRaw;

    final je = (jailEnabledRaw is bool) ? jailEnabledRaw : state.jailEnabled;
    final jr = (jailRadiusRaw is num)
        ? jailRadiusRaw.toDouble()
        : state.jailRadiusM;
    GeoPointDto? jc;
    if (jailCenterRaw is Map) {
      try {
        final m = jailCenterRaw.cast<String, dynamic>();
        jc = GeoPointDto.fromJson(m);
      } catch (_) {
        jc = null;
      }
    }

    final mpClamped = mp.clamp(2, 12);
    final nextPolice = _derivePoliceCount(
      maxPlayers: mpClamped,
      preferExisting: state.policeCount,
      keepExisting: state.policeCountCustomized,
    );

    state = state.copyWith(
      gameMode: gm,
      maxPlayers: mpClamped,
      policeCount: nextPolice,
      contactMode: cm,
      timeLimitSec: tls.clamp(300, 1800),
      durationMin: (tls.clamp(300, 1800) / 60).round(),
      jailEnabled: je,
      jailRadiusM: (jr == null)
          ? null
          : jr.clamp(_minJailRadiusM, _maxJailRadiusM).toDouble(),
      jailCenter: jc,
      zonePolygon: null,
    );
  }

  int _derivePoliceCount({
    required int maxPlayers,
    required int preferExisting,
    required bool keepExisting,
  }) {
    final minP = 1;
    final maxP = (maxPlayers - 1).clamp(1, 9999);
    if (keepExisting) return preferExisting.clamp(minP, maxP);
    final base = (maxPlayers * _defaultPoliceRatio).floor();
    return base.clamp(minP, maxP);
  }
}
