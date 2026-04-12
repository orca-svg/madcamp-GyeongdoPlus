import 'dart:math' as math;

import '../../providers/match_rules_provider.dart';

enum RoomCreateMode { normal, item, ability }

enum RoomContactMode { nonContact, contact }

enum RoomReleaseScope { partial, all }

enum RoomReleaseOrder { fifo, lifo }

class ZoneSetupResult {
  final List<GeoPointDto> polygon;
  final GeoPointDto jailCenter;
  final double jailRadiusM;

  const ZoneSetupResult({
    required this.polygon,
    required this.jailCenter,
    required this.jailRadiusM,
  });
}

class RoomCreateFormState {
  static const Object _unset = Object();

  final RoomCreateMode mode;
  final int maxPlayers;
  final int timeLimitSec;
  final RoomContactMode contactMode;
  final RoomReleaseScope releaseScope;
  final RoomReleaseOrder releaseOrder;
  final double policeRatio;
  final List<GeoPointDto>? polygon;
  final GeoPointDto? jailCenter;
  final double? jailRadiusM;

  const RoomCreateFormState({
    required this.mode,
    required this.maxPlayers,
    required this.timeLimitSec,
    required this.contactMode,
    required this.releaseScope,
    required this.releaseOrder,
    required this.policeRatio,
    required this.polygon,
    required this.jailCenter,
    required this.jailRadiusM,
  });

  factory RoomCreateFormState.initial() => const RoomCreateFormState(
    mode: RoomCreateMode.normal,
    maxPlayers: 8,
    timeLimitSec: 600,
    contactMode: RoomContactMode.nonContact,
    releaseScope: RoomReleaseScope.partial,
    releaseOrder: RoomReleaseOrder.fifo,
    policeRatio: 0.25,
    polygon: null,
    jailCenter: null,
    jailRadiusM: 12,
  );

  RoomCreateFormState copyWith({
    RoomCreateMode? mode,
    int? maxPlayers,
    int? timeLimitSec,
    RoomContactMode? contactMode,
    RoomReleaseScope? releaseScope,
    RoomReleaseOrder? releaseOrder,
    double? policeRatio,
    Object? polygon = _unset,
    Object? jailCenter = _unset,
    Object? jailRadiusM = _unset,
  }) {
    return RoomCreateFormState(
      mode: mode ?? this.mode,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      timeLimitSec: timeLimitSec ?? this.timeLimitSec,
      contactMode: contactMode ?? this.contactMode,
      releaseScope: releaseScope ?? this.releaseScope,
      releaseOrder: releaseOrder ?? this.releaseOrder,
      policeRatio: policeRatio ?? this.policeRatio,
      polygon: polygon == _unset ? this.polygon : polygon as List<GeoPointDto>?,
      jailCenter: jailCenter == _unset
          ? this.jailCenter
          : jailCenter as GeoPointDto?,
      jailRadiusM: jailRadiusM == _unset
          ? this.jailRadiusM
          : jailRadiusM as double?,
    );
  }
}

String _modeWire(RoomCreateMode m) => switch (m) {
  RoomCreateMode.normal => 'NORMAL',
  RoomCreateMode.item => 'ITEM',
  RoomCreateMode.ability => 'ABILITY',
};

String _contactModeWire(RoomContactMode m) => switch (m) {
  RoomContactMode.nonContact => 'NON_CONTACT',
  RoomContactMode.contact => 'CONTACT',
};

String _releaseOrderWire(RoomReleaseOrder o) => switch (o) {
  RoomReleaseOrder.fifo => 'FIFO',
  RoomReleaseOrder.lifo => 'LIFO',
};

Map<String, dynamic> buildRoomCreatePayload(RoomCreateFormState state) {
  final maxPlayers = state.maxPlayers.clamp(3, 50);
  final timeLimit = state.timeLimitSec.clamp(300, 1800);

  final polygon = state.polygon ?? const <GeoPointDto>[];
  final jailCenter = state.jailCenter;
  final jailRadiusM = (state.jailRadiusM ?? 12).clamp(1, 200);

  final releaseCount = (state.releaseScope == RoomReleaseScope.all)
      ? (maxPlayers - 1)
      : 3;

  return <String, dynamic>{
    'mode': _modeWire(state.mode),
    'maxPlayers': maxPlayers,
    'timeLimit': timeLimit,
    'mapConfig': <String, dynamic>{
      'polygon': polygon.map((p) => p.toJson()).toList(growable: false),
      if (jailCenter != null)
        'jail': <String, dynamic>{
          'lat': jailCenter.lat,
          'lng': jailCenter.lng,
          'radiusM': jailRadiusM,
        },
    },
    'rules': <String, dynamic>{
      'contactMode': _contactModeWire(state.contactMode),
      'captureRule': <String, dynamic>{
        'ruleType': 'THREE_OF_THREE',
        'nearThresholdM': 1.0,
        'nearMinHoldMs': 2500,
        'speedMaxMps': 1.2,
        'minConfirmMs': 1500,
        'decayMs': 800,
        'cooldownAfterCaptureMs': 2000,
      },
      'jailRule': <String, dynamic>{
        'jailEnabled': true,
        'rescue': <String, dynamic>{
          'type': 'CHANNELING',
          'rangeM': 10,
          'channelMs': 8000,
          'releaseCount': releaseCount,
          'queuePolicy': _releaseOrderWire(state.releaseOrder),
        },
      },
      'opponentReveal': <String, dynamic>{
        'policy': 'LIMITED',
        'radarPingTtlMs': 7000,
      },
      'policeRatio': state.policeRatio,
    },
  };
}

List<GeoPointDto> buildCircularZonePolygon({
  required GeoPointDto center,
  required double radiusM,
  int vertices = 16,
}) {
  final safeVertices = vertices.clamp(8, 64).toInt();
  const earthRadiusM = 6378137.0;
  final angularDistance = radiusM / earthRadiusM;
  final lat1 = _degToRad(center.lat);
  final lng1 = _degToRad(center.lng);

  return [
    for (var i = 0; i < safeVertices; i++)
      _pointAtBearing(
        lat1: lat1,
        lng1: lng1,
        angularDistance: angularDistance,
        bearingRad: (2 * math.pi * i) / safeVertices,
      ),
  ];
}

GeoPointDto _pointAtBearing({
  required double lat1,
  required double lng1,
  required double angularDistance,
  required double bearingRad,
}) {
  final lat2 = math.asin(
    math.sin(lat1) * math.cos(angularDistance) +
        math.cos(lat1) * math.sin(angularDistance) * math.cos(bearingRad),
  );
  final lng2 =
      lng1 +
      math.atan2(
        math.sin(bearingRad) * math.sin(angularDistance) * math.cos(lat1),
        math.cos(angularDistance) - math.sin(lat1) * math.sin(lat2),
      );

  return GeoPointDto(lat: _radToDeg(lat2), lng: _radToDeg(lng2)).clamp();
}

double _degToRad(double degrees) => degrees * math.pi / 180.0;

double _radToDeg(double radians) => radians * 180.0 / math.pi;
