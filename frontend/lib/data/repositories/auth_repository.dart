import 'package:dio/dio.dart';
import '../../data/api/auth_api.dart';
import '../../data/dto/auth_dto.dart';
import 'repository_result.dart';

class AuthRepository {
  final AuthApi _api;

  AuthRepository(this._api);

  Future<RepositoryResult<AuthDataDto>> signup(
    String email,
    String password,
    String nickname,
  ) async {
    try {
      final response = await _api.signup(
        LocalSignupDto(email: email, password: password, nickname: nickname),
      );
      if (response.success == true && response.data != null) {
        return RepositoryResult.success(response.data!);
      } else {
        return RepositoryResult.failure(response.message ?? 'Signup failed');
      }
    } catch (e) {
      if (e is DioException) {
        // Handle 409 etc. checking e.response
        return RepositoryResult.failure('Network Error: ${e.message}');
      }
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<AuthDataDto>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _api.login(
        LocalLoginDto(email: email, password: password),
      );
      if (response.success == true && response.data != null) {
        return RepositoryResult.success(response.data!);
      } else {
        return RepositoryResult.failure(response.message ?? 'Login failed');
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<KakaoAuthDataDto>> kakaoLogin(String token) async {
    try {
      final response = await _api.kakaoLogin(
        KakaoLoginDto(kakaoAccessToken: token),
      );
      if (response.success == true && response.data != null) {
        // Manually construct KakaoAuthDataDto
        // response.data is AuthDataDto
        // response.isNewUser is bool? (at root)
        final authData = response.data!;
        final isNewUser = response.isNewUser ?? false; // Safe default

        return RepositoryResult.success(
          KakaoAuthDataDto(
            accessToken: authData.accessToken,
            refreshToken: authData.refreshToken,
            expiresIn: authData.expiresIn,
            user: authData.user,
            isNewUser: isNewUser,
          ),
        );
      } else {
        return RepositoryResult.failure(
          response.message ?? 'Kakao login failed',
        );
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<String>> checkNickname(String nickname) async {
    try {
      final response = await _api.checkNickname(nickname);
      if (response.success == true && response.data != null) {
        // response.data is CheckNicknameData { isAvailable: bool }
        if (response.data!.isAvailable) {
          return const RepositoryResult.success("Available");
        } else {
          return const RepositoryResult.failure("Already taken");
        }
      } else {
        return RepositoryResult.failure(
          response.message ?? 'Check nickname failed',
        );
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }
}
