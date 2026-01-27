import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dto/lobby_dto.dart';
import '../models/game_config.dart';
import '../net/socket/socket_io_client_provider.dart';
import 'app_providers.dart';
import 'auth_provider.dart';
import 'match_rules_provider.dart';

enum Team { police, thief }

enum RoomStatus { idle, loading, success, error }

class RoomMember {
  final String id;
  final String name;
  final Team team;
  final bool ready;
  final bool isHost;

  const RoomMember({
    required this.id,
    required this.name,
    required this.team,
    required this.ready,
    required this.isHost,
  });

  RoomMember copyWith({
    String? id,
    String? name,
    Team? team,
    bool? ready,
    bool? isHost,
  }) {
    return RoomMember(
      id: id ?? this.id,
      name: name ?? this.name,
      team: team ?? this.team,
      ready: ready ?? this.ready,
      isHost: isHost ?? this.isHost,
    );
  }
}

class RoomState {
  final bool inRoom;
  final RoomStatus status;
  final String roomId;
  final String roomCode;
  final String myId;
  final String? errorMessage;
  final List<RoomMember> members;
  final GameConfig? config;
  final Map<String, dynamic>? mapConfig;

  const RoomState({
    required this.inRoom,
    required this.status,
    required this.roomId,
    required this.roomCode,
    required this.myId,
    required this.errorMessage,
    required this.members,
    required this.config,
    this.mapConfig,
  });

  factory RoomState.initial() => const RoomState(
    inRoom: false,
    status: RoomStatus.idle,
    roomId: '',
    roomCode: '',
    myId: '',
    errorMessage: null,
    members: [],
    config: null,
    mapConfig: null,
  );

  RoomState copyWith({
    bool? inRoom,
    RoomStatus? status,
    String? roomId,
    String? roomCode,
    String? myId,
    String? errorMessage,
    List<RoomMember>? members,
    GameConfig? config,
    Map<String, dynamic>? mapConfig,
  }) {
    return RoomState(
      inRoom: inRoom ?? this.inRoom,
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      myId: myId ?? this.myId,
      errorMessage: errorMessage ?? this.errorMessage,
      members: members ?? this.members,
      config: config ?? this.config,
      mapConfig: mapConfig ?? this.mapConfig,
    );
  }

  // Getters
  RoomMember? get me {
    try {
      return members.firstWhere((m) => m.id == myId);
    } catch (_) {
      return null;
    }
  }

  int get policeCount => members.where((m) => m.team == Team.police).length;
  int get thiefCount => members.where((m) => m.team == Team.thief).length;
  bool get amIHost => me?.isHost ?? false;

  bool get allReady => members.every((m) => m.isHost || m.ready);

  bool isGameStartable(int maxPlayers) {
    if (members.length < 2) return false;
    if (!allReady) return false;
    // Ensure at least one police and one thief
    final police = policeCount;
    final thief = thiefCount;
    if (police < 1 || thief < 1) return false;
    return true;
  }
}

class RoomController extends Notifier<RoomState> {
  final Random _rand = Random();

  @override
  RoomState build() {
    // Listen to socket events
    _listenSocketEvents();
    return RoomState.initial();
  }

  void _listenSocketEvents() {
    final eventStream = ref.read(socketIoClientProvider.notifier).events;
    eventStream.listen((event) {
      if (!state.inRoom) return;

      switch (event.name) {
        case 'joined_room':
          // Full sync on join
          if (event.payload.containsKey('room')) {
            _syncFromPayload(event.payload['room']);
          }
          break;

        case 'room_updated':
          // Full or partial update
          if (event.payload.containsKey('room')) {
            _syncFromPayload(event.payload['room']);
          } else {
            _syncFromPayload(event.payload);
          }
          break;

        case 'settings_updated':
          try {
            final cfg = GameConfig.fromJson(event.payload);
            state = state.copyWith(config: cfg);
          } catch (e) {
            debugPrint('[ROOM] Config parse error: $e');
          }
          break;

        case 'team_changed':
          // The server should send the updated member list or we handle it via room_updated.
          break;

        case 'member_updated':
          // Sometimes server sends member list
          if (event.payload['members'] is List) {
            _parseAndSetMembers(event.payload['members']);
          }
          break;

        case 'full_rules_update':
          try {
            // Map config might be in here too
            if (event.payload['mapConfig'] is Map) {
              state = state.copyWith(mapConfig: event.payload['mapConfig']);
            }

            ref
                .read(matchRulesProvider.notifier)
                .applyOfflineRoomConfig(event.payload);
          } catch (e) {
            debugPrint('[ROOM] Rules sync error: $e');
          }
          break;
      }
    });
  }

  void _syncFromPayload(Map<String, dynamic> data) {
    var newState = state;

    // 1. Config
    if (data['config'] != null) {
      try {
        newState = newState.copyWith(
          config: GameConfig.fromJson(data['config']),
        );
      } catch (_) {}
    } else if (data['gameMode'] != null) {
      // Flattened config?
      try {
        newState = newState.copyWith(config: GameConfig.fromJson(data));
      } catch (_) {}
    }

    // 2. Members
    if (data['members'] is List) {
      final list = (data['members'] as List).map((x) {
        return RoomMember(
          id: x['userId'] ?? '',
          name: x['nickname'] ?? 'Unknown',
          team: (x['team'] == 'POLICE') ? Team.police : Team.thief,
          ready: x['isReady'] ?? false,
          isHost: x['isHost'] ?? false,
        );
      }).toList();
      newState = newState.copyWith(members: list);
    }

    // 3. Map Config
    if (data['mapConfig'] is Map) {
      newState = newState.copyWith(mapConfig: data['mapConfig']);
    }

    state = newState;
  }

  void _parseAndSetMembers(List<dynamic> rawList) {
    final list = rawList.map((x) {
      return RoomMember(
        id: x['userId'] ?? '',
        name: x['nickname'] ?? 'Unknown',
        team: (x['team'] == 'POLICE') ? Team.police : Team.thief,
        ready: x['isReady'] ?? false,
        isHost: x['isHost'] ?? false,
      );
    }).toList();
    state = state.copyWith(members: list);
  }

  void updateConfig(GameConfig config) {
    if (!state.amIHost) return;
    state = state.copyWith(config: config);
    ref
        .read(socketIoClientProvider.notifier)
        .emit('update_settings', config.toJson());
  }

  void enterLobbyOffline({required String myName}) {
    final myId = _newId();
    state = RoomState(
      inRoom: true,
      status: RoomStatus.success,
      roomId: 'offline_${_newId()}',
      roomCode: 'OFFLINE',
      myId: myId,
      errorMessage: null,
      members: [
        RoomMember(
          id: myId,
          name: myName.trim().isEmpty ? '김선수' : myName.trim(),
          team: Team.police,
          ready: false,
          isHost: true,
        ),
      ],
      config: GameConfig.initial(),
    );
  }

  Future<bool> createRoom({required String myName}) async {
    final name = myName.trim().isEmpty ? '김선수' : myName.trim();
    state = state.copyWith(status: RoomStatus.loading, errorMessage: null);

    final rulesState = ref.read(matchRulesProvider);
    final lobbyRepo = ref.read(lobbyRepositoryProvider);

    // Build Rules Map
    final rulesMap = {
      'contactMode': rulesState.contactMode,
      'jailRule': {
        'rescue': {
          'queuePolicy': rulesState.rescueReleaseOrder,
          'releaseCount': rulesState.rescueReleaseScope == 'PARTIAL' ? 1 : 999,
        },
      },
    };

    // Build MapConfig
    final polygon =
        rulesState.zonePolygon?.map((p) => p.toJson()).toList() ?? [];
    final jail = rulesState.jailCenter != null
        ? {
            'lat': rulesState.jailCenter!.lat,
            'lng': rulesState.jailCenter!.lng,
            'radiusM': rulesState.jailRadiusM ?? 15.0,
          }
        : null;

    final mapConfig = {
      'polygon': polygon,
      'jail':
          jail ??
          {'lat': 37.5665, 'lng': 126.9780, 'radiusM': 15.0}, // Fallback
    };

    // Create DTO
    final dto = CreateRoomDto(
      mode: rulesState.gameMode.wire,
      maxPlayers: rulesState.maxPlayers,
      timeLimit: rulesState.timeLimitSec,
      rules: rulesMap,
      mapConfig: mapConfig,
    );

    final result = await lobbyRepo.createRoom(dto);

    if (result.success && result.data != null) {
      final data = result.data!;
      final myId = _newId();
      state = RoomState(
        inRoom: true,
        status: RoomStatus.success,
        roomId: data.matchId,
        roomCode: data.roomCode,
        myId: myId,
        errorMessage: null,
        members: [
          RoomMember(
            id: myId,
            name: name,
            team: Team.police,
            ready: false,
            isHost: true,
          ),
        ],
        config: GameConfig.initial(),
      );

      // Connect to Socket.IO with JWT token
      final jwtToken = ref.read(authProvider).accessToken;
      if (jwtToken != null) {
        await ref
            .read(socketIoClientProvider.notifier)
            .connect(jwtToken: jwtToken, matchId: data.matchId);
        ref.read(socketIoClientProvider.notifier).emitJoinRoom(data.matchId);
        debugPrint('[ROOM] Socket connected for room: ${data.matchId}');
      } else {
        debugPrint('[ROOM] No JWT token available for socket connection');
      }
      return true;
    } else {
      state = RoomState.initial().copyWith(
        status: RoomStatus.error,
        errorMessage: result.errorMessage ?? 'Failed to create room',
      );
      return false;
    }
  }

  Future<bool> joinRoom({required String myName, required String code}) async {
    final name = myName.trim().isEmpty ? '김선수' : myName.trim();
    final normalizedCode = _normalizeCode(code);
    state = state.copyWith(status: RoomStatus.loading, errorMessage: null);

    final lobbyRepo = ref.read(lobbyRepositoryProvider);
    final result = await lobbyRepo.joinRoom(normalizedCode);

    if (result.success && result.data != null) {
      final data = result.data!;
      final myId = _newId();

      // Mock participants (host is a placeholder since backend might not send details yet)
      final host = RoomMember(
        id: data.hostId,
        name: 'Host', // Backend doesn't provide host name in join response
        team: Team.police,
        ready: false,
        isHost: true,
      );
      final me = RoomMember(
        id: myId,
        name: name,
        team: Team.thief,
        ready: false,
        isHost: false,
      );

      state = RoomState(
        inRoom: true,
        status: RoomStatus.success,
        roomId: data.matchId,
        roomCode: normalizedCode,
        myId: myId,
        errorMessage: null,
        members: [host, me],
        config: GameConfig.initial(),
        mapConfig: data.mapConfig,
      );

      final jwtToken = ref.read(authProvider).accessToken;
      if (jwtToken != null) {
        await ref
            .read(socketIoClientProvider.notifier)
            .connect(jwtToken: jwtToken, matchId: data.matchId);
        ref.read(socketIoClientProvider.notifier).emitJoinRoom(data.matchId);
      }
      return true;
    } else {
      state = state.copyWith(
        status: RoomStatus.error,
        errorMessage: result.errorMessage ?? 'Failed to join room',
      );
      return false;
    }
  }

  void leaveRoom() {
    state = RoomState.initial();
    ref.read(matchRulesProvider.notifier).reset();
    ref.read(socketIoClientProvider.notifier).disconnect();
  }

  void reset() {
    state = RoomState.initial();
  }

  void toggleReady() {
    // We can't access 'state.me' here if 'me' is a getter on state
    // but 'state' is RoomState, so yes we can.
    final me = state.me;
    if (me == null) return;
    state = state.copyWith(
      members: [
        for (final m in state.members)
          if (m.id == state.myId) m.copyWith(ready: !m.ready) else m,
      ],
    );
    // TODO: emit ready
  }

  void setMyReady(bool ready) {
    final me = state.me;
    if (me == null) return;
    if (me.ready == ready) return;
    state = state.copyWith(
      members: [
        for (final m in state.members)
          if (m.id == state.myId) m.copyWith(ready: ready) else m,
      ],
    );
    // TODO: emit ready
  }

  void setMyTeam(Team team) {
    final me = state.me;
    if (me == null) return;
    if (me.ready) return;
    state = state.copyWith(
      members: [
        for (final m in state.members)
          if (m.id == state.myId) m.copyWith(team: team) else m,
      ],
    );
    // Send socket event
    ref.read(socketIoClientProvider.notifier).emit('change_team', {
      'team': team == Team.police ? 'POLICE' : 'THIEF',
    });
  }

  void setHostId(String memberId) {
    if (state.members.isEmpty) return;
    state = state.copyWith(
      members: [
        for (final m in state.members) m.copyWith(isHost: m.id == memberId),
      ],
    );
  }

  void addFakeMember() {
    if (!state.inRoom) return;

    const names = ['참가자C', '참가자D'];
    final existing = state.members.map((m) => m.name).toSet();
    final name = names.firstWhere(
      (n) => !existing.contains(n),
      orElse: () => '참가자${state.members.length + 1}',
    );

    final police = state.policeCount;
    final thief = state.thiefCount;
    final team = (police <= thief) ? Team.police : Team.thief;

    state = state.copyWith(
      members: [
        ...state.members,
        RoomMember(
          id: _newId(),
          name: name,
          team: team,
          ready: false,
          isHost: false,
        ),
      ],
    );
  }

  void toggleFakeReadyAll() {
    if (!state.inRoom) return;
    if (state.members.isEmpty) return;

    final others = state.members.where((m) => m.id != state.myId).toList();
    if (others.isEmpty) return;

    final shouldReady = others.any((m) => !m.ready);

    state = state.copyWith(
      members: [
        for (final m in state.members)
          if (m.id == state.myId) m else m.copyWith(ready: shouldReady),
      ],
    );
  }

  void addBots({required int count}) {
    for (var i = 0; i < count; i++) {
      addFakeMember();
    }
  }

  void setBotsReady({required bool ready}) {
    if (!state.inRoom) return;
    if (state.members.isEmpty) return;
    state = state.copyWith(
      members: [
        for (final m in state.members)
          if (m.id == state.myId) m else m.copyWith(ready: ready),
      ],
    );
  }

  String _newRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final len = 4 + _rand.nextInt(3); // 4~6
    return List.generate(len, (_) => chars[_rand.nextInt(chars.length)]).join();
  }

  String _normalizeCode(String raw) {
    final trimmed = raw.trim().toUpperCase();
    final cleaned = trimmed.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.isEmpty) return _newRoomCode();
    if (cleaned.length <= 6) return cleaned;
    return cleaned.substring(0, 6);
  }

  String _newId() =>
      'm_${DateTime.now().microsecondsSinceEpoch}_${_rand.nextInt(1 << 20)}';
}

final roomProvider = NotifierProvider<RoomController, RoomState>(
  RoomController.new,
);
