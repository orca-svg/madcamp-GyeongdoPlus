import 'package:json_annotation/json_annotation.dart';
import '../models/user_model.dart';

part 'auth_dto.g.dart';

/// 카카오 로그인 요청
@JsonSerializable()
class KakaoLoginRequest {
  final String kakaoAccessToken;

  const KakaoLoginRequest({
    required this.kakaoAccessToken,
  });

  factory KakaoLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$KakaoLoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$KakaoLoginRequestToJson(this);
}

/// 토큰 갱신 요청
@JsonSerializable()
class RefreshRequest {
  final String refreshToken;

  const RefreshRequest({
    required this.refreshToken,
  });

  factory RefreshRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshRequestToJson(this);
}

/// 인증 응답 (로그인, 토큰 갱신)
@JsonSerializable()
class AuthResponse {
  final bool success;
  final AuthResponseData? data;
  final String? error;

  const AuthResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class AuthResponseData {
  final String accessToken;
  final String refreshToken;
  final UserModel? user;

  const AuthResponseData({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory AuthResponseData.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDataFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseDataToJson(this);
}

/// 닉네임 중복 확인 응답
@JsonSerializable()
class CheckNicknameResponse {
  final bool success;
  final CheckNicknameData? data;
  final String? error;

  const CheckNicknameResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory CheckNicknameResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckNicknameResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CheckNicknameResponseToJson(this);
}

@JsonSerializable()
class CheckNicknameData {
  final bool available;

  const CheckNicknameData({
    required this.available,
  });

  factory CheckNicknameData.fromJson(Map<String, dynamic> json) =>
      _$CheckNicknameDataFromJson(json);

  Map<String, dynamic> toJson() => _$CheckNicknameDataToJson(this);
}
