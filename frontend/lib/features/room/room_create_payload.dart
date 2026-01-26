enum RoomCreateMode { normal, item, ability }

enum RoomContactMode { nonContact, contact }

class RoomCreateFormState {
  final RoomCreateMode mode;
  final int maxPlayers;
  final int timeLimitSec;
  final RoomContactMode contactMode;
  final bool jailEnabled;

  const RoomCreateFormState({
    required this.mode,
    required this.maxPlayers,
    required this.timeLimitSec,
    required this.contactMode,
    required this.jailEnabled,
  });

  factory RoomCreateFormState.initial() => const RoomCreateFormState(
    mode: RoomCreateMode.normal,
    maxPlayers: 8,
    timeLimitSec: 600,
    contactMode: RoomContactMode.nonContact,
    jailEnabled: true,
  );

  RoomCreateFormState copyWith({
    RoomCreateMode? mode,
    int? maxPlayers,
    int? timeLimitSec,
    RoomContactMode? contactMode,
    bool? jailEnabled,
  }) {
    return RoomCreateFormState(
      mode: mode ?? this.mode,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      timeLimitSec: timeLimitSec ?? this.timeLimitSec,
      contactMode: contactMode ?? this.contactMode,
      jailEnabled: jailEnabled ?? this.jailEnabled,
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

/// Assemble a room-create payload without any side effects.
///
/// This payload is intentionally "mapping-friendly" rather than server-perfect:
/// next step can adapt keys/shape to the final WS schema.
Map<String, dynamic> buildRoomCreatePayload(RoomCreateFormState state) {
  final maxPlayers = state.maxPlayers.clamp(2, 12);
  final timeLimitSec = state.timeLimitSec.clamp(300, 1800);

  return <String, dynamic>{
    'mode': _modeWire(state.mode),
    'maxPlayers': maxPlayers,
    'timeLimitSec': timeLimitSec,
    'rules': <String, dynamic>{
      'capture': <String, dynamic>{
        'contactMode': _contactModeWire(state.contactMode),
      },
      'zone': <String, dynamic>{'polygon': null},
      'jail': <String, dynamic>{
        'enabled': state.jailEnabled,
        'radiusM': 12,
        'center': null,
      },
      'rescue': <String, dynamic>{
        'type': 'CHANNELING',
        'rangeM': 10,
        'channelMs': 8000,
        'releaseCount': 3,
        'queuePolicy': 'FIFO',
      },
      'opponentReveal': <String, dynamic>{
        'policy': 'LIMITED',
        'radarPingTtlMs': 7000,
      },
    },
  };
}
