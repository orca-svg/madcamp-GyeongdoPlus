import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/lobby_api.dart';
import 'dto/lobby_dto.dart';

class RoomInfo {
  final String roomId;
  final String code;
  final String hostName;

  const RoomInfo({
    required this.roomId,
    required this.code,
    required this.hostName,
  });
}

class RoomResult<T> {
  final T? data;
  final String? errorMessage;

  const RoomResult._({this.data, this.errorMessage});

  bool get ok => data != null;

  factory RoomResult.ok(T data) => RoomResult._(data: data);
  factory RoomResult.fail(String message) =>
      RoomResult._(errorMessage: message);
}

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final lobbyApi = ref.watch(lobbyApiProvider);
  return RoomRepository(lobbyApi);
});

class RoomRepository {
  final LobbyApi _lobbyApi;

  RoomRepository(this._lobbyApi);

  Future<RoomResult<RoomInfo>> createRoom({
    required String myName,
    String mode = 'NORMAL',
    int maxPlayers = 5,
    int timeLimit = 600,
    required Map<String, dynamic> rules,
    required Map<String, dynamic> mapConfig,
  }) async {
    try {
      final request = CreateRoomRequest(
        mode: mode,
        maxPlayers: maxPlayers,
        timeLimit: timeLimit,
        rules: rules,
        mapConfig: mapConfig,
      );

      final response = await _lobbyApi.createRoom(request);

      if (response.success && response.data != null) {
        final data = response.data!;
        return RoomResult.ok(
          RoomInfo(
            roomId: data.matchId,
            code: data.roomCode,
            hostName: myName.isEmpty ? '김선수' : myName,
          ),
        );
      } else {
        return RoomResult.fail(response.error ?? '방 생성 실패');
      }
    } catch (e) {
      return RoomResult.fail('네트워크 오류: $e');
    }
  }

  Future<RoomResult<RoomInfo>> joinRoom({
    required String myName,
    required String code,
  }) async {
    try {
      final request = JoinRoomRequest(roomCode: code.toUpperCase());
      final response = await _lobbyApi.joinRoom(request);

      if (response.success && response.data != null) {
        final data = response.data!;
        return RoomResult.ok(
          RoomInfo(
            roomId: data.matchId,
            code: code.toUpperCase(),
            hostName: '방장', // Backend should provide this
          ),
        );
      } else {
        return RoomResult.fail(response.error ?? '방 참가 실패');
      }
    } catch (e) {
      return RoomResult.fail('네트워크 오류: $e');
    }
  }
}
