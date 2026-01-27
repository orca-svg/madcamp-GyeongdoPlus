import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_client.dart';
import '../models/user_model.dart';

/// User API Provider
final userApiProvider = Provider<UserApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return UserApi(client.dio);
});

/// User API 클래스
class UserApi {
  final Dio _dio;

  UserApi(this._dio);

  /// 내 프로필 조회
  /// GET /user/me
  Future<UserModel?> getMyProfile() async {
    try {
      final response = await _dio.get('/user/me');
      if (response.data['success'] == true && response.data['data'] != null) {
        return UserModel.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[UserApi] getMyProfile error: ${e.message}');
      return null;
    }
  }

  /// 전적 조회
  /// GET /user/me/history
  Future<List<Map<String, dynamic>>> getMyHistory() async {
    try {
      final response = await _dio.get('/user/me/history');
      if (response.data['success'] == true &&
          response.data['history'] is List) {
        return List<Map<String, dynamic>>.from(response.data['history']);
      }
      return [];
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[UserApi] getMyHistory error: ${e.message}');
      return [];
    }
  }

  /// 회원 탈퇴
  /// DELETE /user/me
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _dio.delete('/user/me');
      return response.data ?? {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data['error'] ?? e.message ?? 'Account deletion failed',
      };
    }
  }
}
