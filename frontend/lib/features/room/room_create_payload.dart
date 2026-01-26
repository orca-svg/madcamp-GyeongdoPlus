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
  final RoomCreateMode mode;
  final int maxPlayers;
  final int timeLimitSec;
  final RoomContactMode contactMode;
  final RoomReleaseScope releaseScope;
  final RoomReleaseOrder releaseOrder;
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
    List<GeoPointDto>? polygon,
    GeoPointDto? jailCenter,
    double? jailRadiusM,
  }) {
    return RoomCreateFormState(
      mode: mode ?? this.mode,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      timeLimitSec: timeLimitSec ?? this.timeLimitSec,
      contactMode: contactMode ?? this.contactMode,
      releaseScope: releaseScope ?? this.releaseScope,
      releaseOrder: releaseOrder ?? this.releaseOrder,
      polygon: polygon ?? this.polygon,
      jailCenter: jailCenter ?? this.jailCenter,
      jailRadiusM: jailRadiusM ?? this.jailRadiusM,
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

  final polygon = state.polygon ?? _dummyPolygon();
  final jailCenter = state.jailCenter ?? _dummyJailCenter();
  final jailRadiusM = (state.jailRadiusM ?? 12).clamp(1, 200);

  final releaseCount =
      (state.releaseScope == RoomReleaseScope.all) ? (maxPlayers - 1) : 3;

  return <String, dynamic>{
    'mode': _modeWire(state.mode),
    'maxPlayers': maxPlayers,
    'timeLimit': timeLimit,
    'mapConfig': <String, dynamic>{
      'polygon': polygon.map((p) => p.toJson()).toList(growable: false),
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
    },
  };
}

List<GeoPointDto> _dummyPolygon() => const [
      GeoPointDto(lat: 37.5675, lng: 126.9782),
      GeoPointDto(lat: 37.5679, lng: 126.9825),
      GeoPointDto(lat: 37.5652, lng: 126.9831),
      GeoPointDto(lat: 37.5648, lng: 126.9790),
    ];

GeoPointDto _dummyJailCenter() => const GeoPointDto(
      lat: 37.5665,
      lng: 126.9812,
    );
