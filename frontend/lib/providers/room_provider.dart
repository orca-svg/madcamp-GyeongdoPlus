import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/room_repository.dart';
import '../models/game_config.dart';
import '../net/socket/socket_io_client_provider.dart';
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

  const RoomState({
    required this.inRoom,
    required this.status,
    required this.roomId,
    required this.roomCode,
    required this.myId,
    required this.errorMessage,
    required this.members,
    required this.config,
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
    );
  }

  RoomMember? get me {
    if (myId.isEmpty) return null;
    for (final m in members) {
      if (m.id == myId) return m;
    }
    return null;
  }

  bool get amIHost => me?.isHost ?? false;
  bool get allReady =>
      inRoom && members.isNotEmpty && members.every((m) => m.ready);

  int get policeCount => members.where((m) => m.team == Team.police).length;
  int get thiefCount => members.where((m) => m.team == Team.thief).length;

  int get effectivePoliceCount {
    if (members.isNotEmpty) return policeCount;
    if (myId.isNotEmpty) return 1;
    return 0;
  }

  int get effectiveThiefCount {
    if (members.isNotEmpty) return thiefCount;
    if (myId.isNotEmpty) return 0;
    return 0;
  }

  bool isGameStartable(int maxPlayers) {
    if (members.length != maxPlayers) return false;
    if (!allReady) return false;
    if (policeCount < 1 || thiefCount < 1) return false;
    return true;
  }
}

final roomProvider = NotifierProvider<RoomController, RoomState>(
  RoomController.new,
);

class RoomController extends Notifier<RoomState> {
  final _rand = Random();

  @override
  RoomState build() {
    _listenSocketEvents();
    return RoomState.initial();
  }

  void _listenSocketEvents() {
    final eventStream = ref.read(socketIoClientProvider.notifier).events;
    eventStream.listen((event) {
      if (!state.inRoom) return;

      switch (event.name) {
        case 'settings_updated':
          try {
            final cfg = GameConfig.fromJson(event.payload);
            state = state.copyWith(config: cfg);
          } catch (e) {
            debugPrint('[ROOM] Config parse error: $e');
          }
          break;

        case 'team_changed':
          // Simplified: In a real app, parse payload to find which user changed team.
          // For now, we rely on 'room_updated' or 'joined_room' for full sync,
          // or optimistic updates are enough for 'me'.
          break;

        case 'room_updated':
          if (event.payload.containsKey('config')) {
            try {
              final cfg = GameConfig.fromJson(event.payload['config']);
              state = state.copyWith(config: cfg);
            } catch (_) {}
          }
          break;
      }
    });
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

  Future<RoomResult<RoomInfo>> createRoom({required String myName}) async {
    final name = myName.trim().isEmpty ? '김선수' : myName.trim();
    state = state.copyWith(status: RoomStatus.loading, errorMessage: null);
    final repo = ref.read(roomRepositoryProvider);
    final result = await repo.createRoom(myName: name);
    if (result.ok) {
      final info = result.data!;
      final myId = _newId();
      state = RoomState(
        inRoom: true,
        status: RoomStatus.success,
        roomId: info.roomId,
        roomCode: info.code,
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
            .connect(jwtToken: jwtToken, matchId: info.roomId);
        ref.read(socketIoClientProvider.notifier).emitJoinRoom(info.roomId);
        debugPrint('[ROOM] Socket connected for room: ${info.roomId}');
      } else {
        debugPrint('[ROOM] No JWT token available for socket connection');
      }
    } else {
      state = RoomState.initial().copyWith(
        status: RoomStatus.error,
        errorMessage: result.errorMessage,
      );
    }
    return result;
  }

  Future<RoomResult<RoomInfo>> joinRoom({
    required String myName,
    required String code,
  }) async {
    final name = myName.trim().isEmpty ? '김선수' : myName.trim();
    final normalizedCode = _normalizeCode(code);
    state = state.copyWith(status: RoomStatus.loading, errorMessage: null);
    final repo = ref.read(roomRepositoryProvider);
    final result = await repo.joinRoom(myName: name, code: normalizedCode);
    if (result.ok) {
      final info = result.data!;
      final myId = _newId();
      // Mock participants
      final host = RoomMember(
        id: _newId(),
        name: info.hostName,
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
        roomId: info.roomId,
        roomCode: normalizedCode,
        myId: myId,
        errorMessage: null,
        members: [host, me],
        config: GameConfig.initial(),
      );

      final jwtToken = ref.read(authProvider).accessToken;
      if (jwtToken != null) {
        await ref
            .read(socketIoClientProvider.notifier)
            .connect(jwtToken: jwtToken, matchId: info.roomId);
        ref.read(socketIoClientProvider.notifier).emitJoinRoom(info.roomId);
      }
    } else {
      state = state.copyWith(
        status: RoomStatus.error,
        errorMessage: result.errorMessage,
      );
    }
    return result;
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
