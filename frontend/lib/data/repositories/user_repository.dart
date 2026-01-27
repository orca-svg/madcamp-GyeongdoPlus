import 'package:dio/dio.dart';

import '../api/user_api.dart';
import '../dto/user_dto.dart';
import 'repository_result.dart';

class UserRepository {
  final UserApi _api;

  UserRepository(this._api);

  Future<RepositoryResult<MyProfileDataDto>> getMyProfile() async {
    try {
      final response = await _api.getMyProfile();
      if (response.success == true && response.data != null) {
        return RepositoryResult.success(response.data!);
      } else {
        return RepositoryResult.failure(
          response.message ?? 'Failed to get profile',
        );
      }
    } on DioException catch (e) {
      // Handle specific HTTP errors
      if (e.response?.statusCode == 404) {
        return RepositoryResult.failure('Profile not found (404)');
      }
      return RepositoryResult.failure(
        'Network error: ${e.message ?? e.toString()}',
      );
    } catch (e) {
      return RepositoryResult.failure('Unexpected error: ${e.toString()}');
    }
  }

  Future<RepositoryResult<OtherUserProfileDataDto>> getUserProfile(
    String userId,
  ) async {
    try {
      final response = await _api.getUserProfile(userId);
      if (response.success == true && response.data != null) {
        return RepositoryResult.success(response.data!);
      } else {
        return RepositoryResult.failure(
          response.message ?? 'Failed to get user profile',
        );
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<UpdateProfileDataDto>> updateProfile({
    String? nickname,
    String? profileImage,
  }) async {
    try {
      final response = await _api.updateProfile(
        UpdateProfileDto(nickname: nickname, profileImage: profileImage),
      );
      if (response.success == true && response.data != null) {
        return RepositoryResult.success(response.data!);
      } else {
        return RepositoryResult.failure(
          response.message ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<List<MatchRecordDto>>> getMatchHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getMatchHistory(
        MatchHistoryQueryDto(page: page, limit: limit),
      );
      if (response.success == true && response.data != null) {
        return RepositoryResult.success(response.data!);
      } else {
        return RepositoryResult.failure(
          response.message ?? 'Failed to get match history',
        );
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<void>> deleteAccount({
    required String reason,
    required bool agreedToLoseData,
  }) async {
    try {
      final response = await _api.deleteAccount(
        DeleteAccountDto(reason: reason, agreedToLoseData: agreedToLoseData),
      );
      if (response.success == true) {
        return const RepositoryResult.success(null);
      } else {
        return RepositoryResult.failure(
          response.message ?? 'Failed to delete account',
        );
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }
}
