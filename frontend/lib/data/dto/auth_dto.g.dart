// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: json['id'] as String,
  email: json['email'] as String,
  nickname: json['nickname'] as String,
  profileImage: json['profileImage'] as String?,
  provider: json['provider'] as String?,
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'nickname': instance.nickname,
  'profileImage': instance.profileImage,
  'provider': instance.provider,
};

AuthDataDto _$AuthDataDtoFromJson(Map<String, dynamic> json) => AuthDataDto(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresIn: (json['expiresIn'] as num).toInt(),
  user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthDataDtoToJson(AuthDataDto instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'user': instance.user,
    };

KakaoAuthDataDto _$KakaoAuthDataDtoFromJson(Map<String, dynamic> json) =>
    KakaoAuthDataDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      isNewUser: json['isNewUser'] as bool,
    );

Map<String, dynamic> _$KakaoAuthDataDtoToJson(KakaoAuthDataDto instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'user': instance.user,
      'isNewUser': instance.isNewUser,
    };

LocalSignupDto _$LocalSignupDtoFromJson(Map<String, dynamic> json) =>
    LocalSignupDto(
      email: json['email'] as String,
      password: json['password'] as String,
      nickname: json['nickname'] as String,
    );

Map<String, dynamic> _$LocalSignupDtoToJson(LocalSignupDto instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'nickname': instance.nickname,
    };

SignupResponseDto _$SignupResponseDtoFromJson(Map<String, dynamic> json) =>
    SignupResponseDto(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : AuthDataDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$SignupResponseDtoToJson(SignupResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

SignupConflictErrorDto _$SignupConflictErrorDtoFromJson(
  Map<String, dynamic> json,
) => SignupConflictErrorDto(
  success: json['success'] as bool,
  error: json['error'],
);

Map<String, dynamic> _$SignupConflictErrorDtoToJson(
  SignupConflictErrorDto instance,
) => <String, dynamic>{'success': instance.success, 'error': instance.error};

LocalLoginDto _$LocalLoginDtoFromJson(Map<String, dynamic> json) =>
    LocalLoginDto(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LocalLoginDtoToJson(LocalLoginDto instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

LoginResponseDto _$LoginResponseDtoFromJson(Map<String, dynamic> json) =>
    LoginResponseDto(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : AuthDataDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$LoginResponseDtoToJson(LoginResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

KakaoLoginDto _$KakaoLoginDtoFromJson(Map<String, dynamic> json) =>
    KakaoLoginDto(kakaoAccessToken: json['kakaoAccessToken'] as String);

Map<String, dynamic> _$KakaoLoginDtoToJson(KakaoLoginDto instance) =>
    <String, dynamic>{'kakaoAccessToken': instance.kakaoAccessToken};

KakaoLoginResponseDto _$KakaoLoginResponseDtoFromJson(
  Map<String, dynamic> json,
) => KakaoLoginResponseDto(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : AuthDataDto.fromJson(json['data'] as Map<String, dynamic>),
  isNewUser: json['isNewUser'] as bool?,
  error: json['error'],
);

Map<String, dynamic> _$KakaoLoginResponseDtoToJson(
  KakaoLoginResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'isNewUser': instance.isNewUser,
  'error': instance.error,
};

RefreshRequestDto _$RefreshRequestDtoFromJson(Map<String, dynamic> json) =>
    RefreshRequestDto(refreshToken: json['refreshToken'] as String);

Map<String, dynamic> _$RefreshRequestDtoToJson(RefreshRequestDto instance) =>
    <String, dynamic>{'refreshToken': instance.refreshToken};

RefreshResponseData _$RefreshResponseDataFromJson(Map<String, dynamic> json) =>
    RefreshResponseData(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$RefreshResponseDataToJson(
  RefreshResponseData instance,
) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
};

RefreshResponseDto _$RefreshResponseDtoFromJson(Map<String, dynamic> json) =>
    RefreshResponseDto(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : RefreshResponseData.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$RefreshResponseDtoToJson(RefreshResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

LogoutResponseDto _$LogoutResponseDtoFromJson(Map<String, dynamic> json) =>
    LogoutResponseDto(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      error: json['error'],
    );

Map<String, dynamic> _$LogoutResponseDtoToJson(LogoutResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'error': instance.error,
    };

CheckNicknameData _$CheckNicknameDataFromJson(Map<String, dynamic> json) =>
    CheckNicknameData(isAvailable: json['isAvailable'] as bool);

Map<String, dynamic> _$CheckNicknameDataToJson(CheckNicknameData instance) =>
    <String, dynamic>{'isAvailable': instance.isAvailable};

CheckNicknameResponseDto _$CheckNicknameResponseDtoFromJson(
  Map<String, dynamic> json,
) => CheckNicknameResponseDto(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : CheckNicknameData.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$CheckNicknameResponseDtoToJson(
  CheckNicknameResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};
