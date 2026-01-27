import 'package:dio/dio.dart';
import '../../data/api/game_api.dart';
import '../../data/dto/game_dto.dart';
import 'repository_result.dart';

class GameRepository {
  final GameApi _api;

  GameRepository(this._api);

  Future<RepositoryResult<MoveResponseDataDto>> move(MoveDto dto) async {
    try {
      final response = await _api.move(dto);
      if (response.success) {
        return RepositoryResult.success(response.data);
      } else {
        return RepositoryResult.failure(response.message);
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<ArrestDataDto>> arrest(String matchId) async {
    try {
      final response = await _api.arrest(ArrestDto(matchId: matchId));
      if (response.success) {
        return RepositoryResult.success(response.data);
      } else {
        return RepositoryResult.failure(response.message);
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  // Add other methods (rescue, item, etc) as needed
}
