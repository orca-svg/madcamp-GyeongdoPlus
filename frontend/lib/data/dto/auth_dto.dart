import 'package:json_annotation/json_annotation.dart';

part 'auth_dto.g.dart';

// ------------------------------------------------------------------
// Shared / Common DTOs
// ------------------------------------------------------------------

@JsonSerializable()
class UserDto {
  final String id;
  final String email;
  final String nickname;
  final String? profileImage;
  final String? provider; // Added to match backend response

  UserDto({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImage,
    this.provider,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

@JsonSerializable()
class AuthDataDto {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserDto user;

  AuthDataDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthDataDto.fromJson(Map<String, dynamic> json) =>
      _$AuthDataDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AuthDataDtoToJson(this);
}

@JsonSerializable()
class KakaoAuthDataDto extends AuthDataDto {
  final bool isNewUser;

  KakaoAuthDataDto({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required UserDto user,
    required this.isNewUser,
  }) : super(
         accessToken: accessToken,
         refreshToken: refreshToken,
         expiresIn: expiresIn,
         user: user,
       );

  factory KakaoAuthDataDto.fromJson(Map<String, dynamic> json) =>
      _$KakaoAuthDataDtoFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$KakaoAuthDataDtoToJson(this);
}

// ------------------------------------------------------------------
// Signup
// ------------------------------------------------------------------

@JsonSerializable()
class LocalSignupDto {
  final String email;
  final String password;
  final String nickname;

  LocalSignupDto({
    required this.email,
    required this.password,
    required this.nickname,
  });

  Map<String, dynamic> toJson() => _$LocalSignupDtoToJson(this);
}

@JsonSerializable()
class SignupResponseDto {
  final bool? success;
  final String? message;
  final AuthDataDto? data;
  final dynamic error;

  SignupResponseDto({this.success, this.message, this.data, this.error});

  factory SignupResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SignupResponseDtoFromJson(json);
}

@JsonSerializable()
class SignupConflictErrorDto {
  final bool success;
  final dynamic error;

  SignupConflictErrorDto({required this.success, this.error});

  factory SignupConflictErrorDto.fromJson(Map<String, dynamic> json) =>
      _$SignupConflictErrorDtoFromJson(json);
}

// ------------------------------------------------------------------
// Login (Local)
// ------------------------------------------------------------------

@JsonSerializable()
class LocalLoginDto {
  final String email;
  final String password;

  LocalLoginDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => _$LocalLoginDtoToJson(this);
}

@JsonSerializable()
class LoginResponseDto {
  final bool? success;
  final String? message;
  final AuthDataDto? data;
  final dynamic error;

  LoginResponseDto({this.success, this.message, this.data, this.error});

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Login (Kakao)
// ------------------------------------------------------------------

@JsonSerializable()
class KakaoLoginDto {
  final String kakaoAccessToken;

  KakaoLoginDto({required this.kakaoAccessToken});

  Map<String, dynamic> toJson() => _$KakaoLoginDtoToJson(this);
}

@JsonSerializable()
class KakaoLoginResponseDto {
  final bool? success;
  final String? message;
  final AuthDataDto? data; // Changed from KakaoAuthDataDto to AuthDataDto
  final bool? isNewUser; // Added root-level field
  final dynamic error;

  KakaoLoginResponseDto({
    this.success,
    this.message,
    this.data,
    this.isNewUser,
    this.error,
  });

  factory KakaoLoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$KakaoLoginResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Refresh
// ------------------------------------------------------------------

@JsonSerializable()
class RefreshRequestDto {
  final String refreshToken;

  RefreshRequestDto({required this.refreshToken});

  Map<String, dynamic> toJson() => _$RefreshRequestDtoToJson(this);
}

@JsonSerializable()
class RefreshResponseData {
  final String accessToken;
  final String refreshToken;

  RefreshResponseData({required this.accessToken, required this.refreshToken});

  factory RefreshResponseData.fromJson(Map<String, dynamic> json) =>
      _$RefreshResponseDataFromJson(json);
}

@JsonSerializable()
class RefreshResponseDto {
  final bool? success;
  final String? message;
  final RefreshResponseData? data;
  final dynamic error;

  RefreshResponseDto({this.success, this.message, this.data, this.error});

  factory RefreshResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Logout
// ------------------------------------------------------------------

@JsonSerializable()
class LogoutResponseDto {
  final bool? success;
  final String? message;
  final dynamic error;

  LogoutResponseDto({this.success, this.message, this.error});

  factory LogoutResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LogoutResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Check Nickname
// ------------------------------------------------------------------

@JsonSerializable()
class CheckNicknameData {
  final bool isAvailable;

  CheckNicknameData({required this.isAvailable});

  factory CheckNicknameData.fromJson(Map<String, dynamic> json) =>
      _$CheckNicknameDataFromJson(json);
}

@JsonSerializable()
class CheckNicknameResponseDto {
  final bool? success;
  final String? message;
  final CheckNicknameData? data;
  final dynamic error;

  CheckNicknameResponseDto({this.success, this.message, this.data, this.error});

  factory CheckNicknameResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CheckNicknameResponseDtoFromJson(json);
}
