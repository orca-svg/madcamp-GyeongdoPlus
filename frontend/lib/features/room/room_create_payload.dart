enum RoomCreateMode { normal, item, ability }

enum RoomContactMode { nonContact, contact }

enum RoomReleaseScope { partial, all }

enum RoomReleaseOrder { fifo, lifo }

class RoomCreateFormState {
  final RoomCreateMode mode;
  final int maxPlayers;
  final int timeLimitSec;
  final RoomContactMode contactMode;
  final RoomReleaseScope releaseScope;
  final RoomReleaseOrder releaseOrder;

  const RoomCreateFormState({
    required this.mode,
    required this.maxPlayers,
    required this.timeLimitSec,
    required this.contactMode,
    required this.releaseScope,
    required this.releaseOrder,
  });

  factory RoomCreateFormState.initial() => const RoomCreateFormState(
    mode: RoomCreateMode.normal,
    maxPlayers: 8,
    timeLimitSec: 600,
    contactMode: RoomContactMode.nonContact,
    releaseScope: RoomReleaseScope.partial,
    releaseOrder: RoomReleaseOrder.fifo,
  );

  RoomCreateFormState copyWith({
    RoomCreateMode? mode,
    int? maxPlayers,
    int? timeLimitSec,
    RoomContactMode? contactMode,
    RoomReleaseScope? releaseScope,
    RoomReleaseOrder? releaseOrder,
  }) {
    return RoomCreateFormState(
      mode: mode ?? this.mode,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      timeLimitSec: timeLimitSec ?? this.timeLimitSec,
      contactMode: contactMode ?? this.contactMode,
      releaseScope: releaseScope ?? this.releaseScope,
      releaseOrder: releaseOrder ?? this.releaseOrder,
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

String _releaseScopeWire(RoomReleaseScope s) => switch (s) {
  RoomReleaseScope.partial => 'PARTIAL',
  RoomReleaseScope.all => 'ALL',
};

String _releaseOrderWire(RoomReleaseOrder o) => switch (o) {
  RoomReleaseOrder.fifo => 'FIFO',
  RoomReleaseOrder.lifo => 'LIFO',
};

/// Assemble a room-create payload without any side effects.
///
/// This payload is intentionally "mapping-friendly" rather than server-perfect:
/// next step can adapt keys/shape to the final WS schema.
Map<String, dynamic> buildRoomCreatePayload(RoomCreateFormState state) {
  final maxPlayers = state.maxPlayers.clamp(3, 50);
  final timeLimitSec = state.timeLimitSec.clamp(300, 1800);

  return <String, dynamic>{
    'mode': _modeWire(state.mode),
    'maxPlayers': maxPlayers,
    'timeLimitSec': timeLimitSec,
    'rules': <String, dynamic>{
      'rescueRule': <String, dynamic>{
        'contactMode': _contactModeWire(state.contactMode),
        'releaseScope': _releaseScopeWire(state.releaseScope),
        if (state.releaseScope == RoomReleaseScope.partial)
          'releaseOrder': _releaseOrderWire(state.releaseOrder),
      },
      'zone': <String, dynamic>{
        'polygon': null,
        'jail': <String, dynamic>{'center': null, 'radiusM': 12},
      },
      'opponentReveal': <String, dynamic>{
        'policy': 'LIMITED',
        'radarPingTtlMs': 7000,
      },
    },
  };
}
