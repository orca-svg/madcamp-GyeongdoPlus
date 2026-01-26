import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/room_repository.dart';
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

  const RoomState({
    required this.inRoom,
    required this.status,
    required this.roomId,
    required this.roomCode,
    required this.myId,
    required this.errorMessage,
    required this.members,
  });

  factory RoomState.initial() =>
      const RoomState(
        inRoom: false,
        status: RoomStatus.idle,
        roomId: '',
        roomCode: '',
        myId: '',
        errorMessage: null,
        members: [],
      );

  RoomState copyWith({
    bool? inRoom,
    RoomStatus? status,
    String? roomId,
    String? roomCode,
    String? myId,
    String? errorMessage,
    List<RoomMember>? members,
  }) {
    return RoomState(
      inRoom: inRoom ?? this.inRoom,
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      myId: myId ?? this.myId,
      errorMessage: errorMessage ?? this.errorMessage,
      members: members ?? this.members,
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

  /// Team counts for validation even when member list is not yet hydrated (offline/early stage).
  /// If there are no members but we have a local player id, treat it as "me=police".
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
}

final roomProvider = NotifierProvider<RoomController, RoomState>(
  RoomController.new,
);

class RoomController extends Notifier<RoomState> {
  final _rand = Random();

  @override
  RoomState build() => RoomState.initial();

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
    );
  }

  Future<RoomResult<RoomInfo>> createRoom({required String myName}) async {
    final name = myName.trim().isEmpty ? '김선수' : myName.trim();
    debugPrint('[ROOM] create start/name=$name');
    state = state.copyWith(
      status: RoomStatus.loading,
      errorMessage: null,
    );
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
      );
      debugPrint('[ROOM] create success/code=${info.code}');
    } else {
      state = RoomState.initial().copyWith(
        status: RoomStatus.error,
        errorMessage: result.errorMessage,
      );
      debugPrint('[ROOM] create fail/error=${result.errorMessage}');
    }
    return result;
  }

  Future<RoomResult<RoomInfo>> joinRoom({
    required String myName,
    required String code,
  }) async {
    final name = myName.trim().isEmpty ? '김선수' : myName.trim();
    final normalizedCode = _normalizeCode(code);
    debugPrint('[ROOM] join start/code=$normalizedCode');
    state = state.copyWith(
      status: RoomStatus.loading,
      errorMessage: null,
    );
    final repo = ref.read(roomRepositoryProvider);
    final result = await repo.joinRoom(
      myName: name,
      code: normalizedCode,
    );
    if (result.ok) {
      final info = result.data!;
      final myId = _newId();
      final host = RoomMember(
        id: _newId(),
        name: info.hostName,
        team: Team.police,
        ready: false,
        isHost: true,
      );
      final other1 = RoomMember(
        id: _newId(),
        name: '참가자A',
        team: Team.thief,
        ready: false,
        isHost: false,
      );
      final other2 = RoomMember(
        id: _newId(),
        name: '참가자B',
        team: Team.police,
        ready: true,
        isHost: false,
      );
      final me = RoomMember(
        id: myId,
        name: name,
        team: Team.police,
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
        members: [host, other1, other2, me],
      );
      debugPrint('[ROOM] join success/roomId=${info.roomId}');
    } else {
      state = RoomState.initial().copyWith(
        status: RoomStatus.error,
        errorMessage: result.errorMessage,
      );
      debugPrint('[ROOM] join fail/error=${result.errorMessage}');
    }
    return result;
  }

  void leaveRoom() {
    state = RoomState.initial();
    ref.read(matchRulesProvider.notifier).reset();
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
