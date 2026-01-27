import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_client.dart';
import '../dto/lobby_dto.dart';

final lobbyApiProvider = Provider<LobbyApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return LobbyApi(client);
});

class LobbyApi {
  final ApiClient _client;

  LobbyApi(this._client);

  /// POST /lobby/create
  Future<CreateRoomResponse> createRoom(CreateRoomRequest request) async {
    try {
      final response = await _client.dio.post(
        '/lobby/create',
        data: request.toJson(),
      );
      return CreateRoomResponse.fromJson(response.data);
    } on DioException catch (e) {
      return CreateRoomResponse(
        success: false,
        error: e.response?.data?['message'] ?? e.message ?? 'Unknown error',
      );
    }
  }

  /// POST /lobby/join
  Future<JoinRoomResponse> joinRoom(JoinRoomRequest request) async {
    try {
      final response = await _client.dio.post(
        '/lobby/join',
        data: request.toJson(),
      );
      return JoinRoomResponse.fromJson(response.data);
    } on DioException catch (e) {
      return JoinRoomResponse(
        success: false,
        error: e.response?.data?['message'] ?? e.message ?? 'Unknown error',
      );
    }
  }

  /// POST /lobby/kick
  Future<Map<String, dynamic>> kickUser(KickUserRequest request) async {
    try {
      final response = await _client.dio.post(
        '/lobby/kick',
        data: request.toJson(),
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Unknown error',
      };
    }
  }

  /// GET /lobby/:matchId
  Future<RoomDetailResponse> getRoomDetail(String matchId) async {
    try {
      final response = await _client.dio.get('/lobby/$matchId');
      return RoomDetailResponse.fromJson(response.data);
    } on DioException catch (e) {
      return RoomDetailResponse(
        success: false,
        error: e.response?.data?['message'] ?? e.message ?? 'Unknown error',
      );
    }
  }

  /// PATCH /lobby/:matchId
  Future<Map<String, dynamic>> updateRoom(
    String matchId,
    UpdateRoomRequest request,
  ) async {
    try {
      final response = await _client.dio.patch(
        '/lobby/$matchId',
        data: request.toJson(),
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Unknown error',
      };
    }
  }

  /// POST /lobby/start
  Future<Map<String, dynamic>> startGame(StartGameRequest request) async {
    try {
      final response = await _client.dio.post(
        '/lobby/start',
        data: request.toJson(),
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Unknown error',
      };
    }
  }
}
