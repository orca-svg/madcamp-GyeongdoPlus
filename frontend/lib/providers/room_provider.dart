import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'match_rules_provider.dart';

enum Team { police, thief }

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
  final String roomCode;
  final String myId;
  final List<RoomMember> members;

  const RoomState({
    required this.inRoom,
    required this.roomCode,
    required this.myId,
    required this.members,
  });

  factory RoomState.initial() => const RoomState(
        inRoom: false,
        roomCode: '',
        myId: '',
        members: [],
      );

  RoomState copyWith({
    bool? inRoom,
    String? roomCode,
    String? myId,
    List<RoomMember>? members,
  }) {
    return RoomState(
      inRoom: inRoom ?? this.inRoom,
      roomCode: roomCode ?? this.roomCode,
      myId: myId ?? this.myId,
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
  bool get allReady => inRoom && members.isNotEmpty && members.every((m) => m.ready);

  int get policeCount => members.where((m) => m.team == Team.police).length;
  int get thiefCount => members.where((m) => m.team == Team.thief).length;
}

final roomProvider = NotifierProvider<RoomController, RoomState>(RoomController.new);

class RoomController extends Notifier<RoomState> {
  final _rand = Random();

  @override
  RoomState build() => RoomState.initial();

  void createRoom({required String myName}) {
    final myId = _newId();
    final code = _newRoomCode();
    state = RoomState(
      inRoom: true,
      roomCode: code,
      myId: myId,
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

  void joinRoom({required String myName, required String code}) {
    final myId = _newId();
    final normalizedCode = _normalizeCode(code);

    final host = RoomMember(
      id: _newId(),
      name: '방장',
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
      name: myName.trim().isEmpty ? '김선수' : myName.trim(),
      team: Team.police,
      ready: false,
      isHost: false,
    );

    state = RoomState(
      inRoom: true,
      roomCode: normalizedCode,
      myId: myId,
      members: [host, other1, other2, me],
    );
  }

  void leaveRoom() {
    state = RoomState.initial();
    ref.read(matchRulesProvider.notifier).reset();
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

  void setMyTeam(Team team) {
    final me = state.me;
    if (me == null) return;
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

  String _newId() => 'm_${DateTime.now().microsecondsSinceEpoch}_${_rand.nextInt(1 << 20)}';
}

