import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomRoleState {
  final bool isHost;
  final String myTeam; // 'POLICE' | 'THIEF'

  const RoomRoleState({required this.isHost, required this.myTeam});

  RoomRoleState copyWith({bool? isHost, String? myTeam}) {
    return RoomRoleState(
      isHost: isHost ?? this.isHost,
      myTeam: myTeam ?? this.myTeam,
    );
  }
}

final roomRoleProvider = NotifierProvider<RoomRoleController, RoomRoleState>(RoomRoleController.new);

class RoomRoleController extends Notifier<RoomRoleState> {
  @override
  RoomRoleState build() => const RoomRoleState(isHost: true, myTeam: 'POLICE');

  void setHost(bool v) => state = state.copyWith(isHost: v);
  void setMyTeam(String team) => state = state.copyWith(myTeam: team);
}

