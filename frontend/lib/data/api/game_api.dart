import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_client.dart';
import '../dto/game_dto.dart';

final gameApiProvider = Provider<GameApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return GameApi(client);
});

class GameApi {
  final ApiClient _client;

  GameApi(this._client);

  /// POST /game/move
  Future<MoveResponse> sendMove(MoveRequest request) async {
    try {
      final response = await _client.dio.post(
        '/game/move',
        data: request.toJson(),
      );
      return MoveResponse.fromJson(response.data);
    } catch (_) {
      return const MoveResponse();
    }
  }

  /// POST /game/arrest
  Future<ArrestResponse?> arrest(ArrestRequest request) async {
    try {
      final response = await _client.dio.post(
        '/game/arrest',
        data: request.toJson(),
      );
      return ArrestResponse.fromJson(response.data);
    } on DioException {
      return null;
    }
  }

  /// POST /game/rescue
  Future<RescueResponse?> rescue(RescueRequest request) async {
    try {
      final response = await _client.dio.post(
        '/game/rescue',
        data: request.toJson(),
      );
      return RescueResponse.fromJson(response.data);
    } on DioException {
      return null;
    }
  }

  /// POST /game/ability/select
  Future<Map<String, dynamic>> selectAbility(
    AbilitySelectRequest request,
  ) async {
    try {
      final response = await _client.dio.post(
        '/game/ability/select',
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

  /// POST /game/ability/use
  Future<Map<String, dynamic>> useAbility(AbilityUseRequest request) async {
    try {
      final response = await _client.dio.post(
        '/game/ability/use',
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

  /// POST /game/item/select
  Future<Map<String, dynamic>> selectItem(ItemSelectRequest request) async {
    try {
      final response = await _client.dio.post(
        '/game/item/select',
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

  /// POST /game/item/use
  Future<Map<String, dynamic>> useItem(ItemUseRequest request) async {
    try {
      final response = await _client.dio.post(
        '/game/item/use',
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

  /// GET /game/:matchId/sync
  Future<GameSyncResponse?> syncGame(String matchId) async {
    try {
      final response = await _client.dio.get('/game/$matchId/sync');
      return GameSyncResponse.fromJson(response.data);
    } on DioException {
      return null;
    }
  }

  /// POST /game/:matchId/end
  Future<GameEndResponse?> endGame(String matchId, {String? reason}) async {
    try {
      final response = await _client.dio.post(
        '/game/$matchId/end',
        data: reason != null ? {'reason': reason} : null,
      );
      return GameEndResponse.fromJson(response.data);
    } on DioException {
      return null;
    }
  }

  /// POST /game/:matchId/rematch
  Future<Map<String, dynamic>> rematch(String matchId) async {
    try {
      final response = await _client.dio.post('/game/$matchId/rematch');
      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Unknown error',
      };
    }
  }

  /// POST /game/:matchId/delegate
  Future<Map<String, dynamic>> delegateHost(
    String matchId,
    String targetUserId,
  ) async {
    try {
      final response = await _client.dio.post(
        '/game/$matchId/delegate',
        data: {'targetUserId': targetUserId},
      );
      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Unknown error',
      };
    }
  }

  /// POST /game/:matchId/leave
  Future<Map<String, dynamic>> leaveGame(String matchId) async {
    try {
      final response = await _client.dio.post('/game/$matchId/leave');
      return response.data;
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Unknown error',
      };
    }
  }
}
