import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_client.dart';
import '../dto/auth_dto.dart';

/// Auth API Provider
final authApiProvider = Provider<AuthApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthApi(client.dio);
});

/// Auth API 클래스
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  /// 카카오 로그인
  /// POST /auth/login/kakao
  Future<AuthResponse> loginWithKakao(KakaoLoginRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/login/kakao',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        error: e.response?.data['error'] ?? e.message ?? 'Login failed',
      );
    }
  }

  /// 토큰 갱신
  /// POST /auth/refresh
  Future<AuthResponse> refreshToken(RefreshRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        error: e.response?.data['error'] ?? e.message ?? 'Token refresh failed',
      );
    }
  }

  /// 로그아웃
  /// POST /auth/logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _dio.post('/auth/logout');
      return response.data ?? {'success': true};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['error'] ?? e.message ?? 'Logout failed',
      };
    }
  }

  /// 닉네임 중복 확인
  /// GET /auth/check-nickname?nickname=xxx
  Future<CheckNicknameResponse> checkNickname(String nickname) async {
    try {
      final response = await _dio.get(
        '/auth/check-nickname',
        queryParameters: {'nickname': nickname},
      );
      return CheckNicknameResponse.fromJson(response.data);
    } on DioException catch (e) {
      return CheckNicknameResponse(
        success: false,
        error:
            e.response?.data['error'] ?? e.message ?? 'Nickname check failed',
      );
    }
  }
}
