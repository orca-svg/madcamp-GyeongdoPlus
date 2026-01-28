import 'package:dio/dio.dart';
import '../../data/api/lobby_api.dart';
import '../../data/dto/lobby_dto.dart';
import 'repository_result.dart';

class LobbyRepository {
  final LobbyApi _api;

  LobbyRepository(this._api);

  Future<RepositoryResult<CreateRoomDataDto>> createRoom(
    CreateRoomDto dto,
  ) async {
    try {
      final response = await _api.createRoom(dto);
      if (response.success == true && response.data != null) {
        return RepositoryResult.success(response.data!);
      } else {
        return RepositoryResult.failure(
          response.message ?? 'Failed to create room',
        );
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<JoinRoomDataDto>> joinRoom(String roomCode) async {
    try {
      final response = await _api.joinRoom(JoinRoomDto(roomCode: roomCode));
      if (response.success == true && response.data != null) {
        return RepositoryResult.success(response.data!);
      } else {
        return RepositoryResult.failure(
          response.message ?? 'Failed to join room',
        );
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<RoomDetailsDataDto>> getRoomDetails(
    String matchId,
  ) async {
    try {
      final response = await _api.getRoomDetails(matchId);
      if (response.success == true && response.data != null) {
        return RepositoryResult.success(response.data!);
      } else {
        return RepositoryResult.failure(
          response.message ?? 'Failed to get room details',
        );
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<StartGameDataDto>> startGame(String matchId) async {
    try {
      final response = await _api.startGame(StartGameDto(matchId: matchId));
      if (response.success == true && response.data != null) {
        return RepositoryResult.success(response.data!);
      } else {
        return RepositoryResult.failure(
          response.message ?? 'Failed to start game',
        );
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }
}
