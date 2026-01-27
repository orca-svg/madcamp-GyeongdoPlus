// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KakaoLoginRequest _$KakaoLoginRequestFromJson(Map<String, dynamic> json) =>
    KakaoLoginRequest(kakaoAccessToken: json['kakaoAccessToken'] as String);

Map<String, dynamic> _$KakaoLoginRequestToJson(KakaoLoginRequest instance) =>
    <String, dynamic>{'kakaoAccessToken': instance.kakaoAccessToken};

RefreshRequest _$RefreshRequestFromJson(Map<String, dynamic> json) =>
    RefreshRequest(refreshToken: json['refreshToken'] as String);

Map<String, dynamic> _$RefreshRequestToJson(RefreshRequest instance) =>
    <String, dynamic>{'refreshToken': instance.refreshToken};

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  success: json['success'] as bool,
  data: json['data'] == null
      ? null
      : AuthResponseData.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'] as String?,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };

AuthResponseData _$AuthResponseDataFromJson(Map<String, dynamic> json) =>
    AuthResponseData(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: json['user'] == null
          ? null
          : UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseDataToJson(AuthResponseData instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };

CheckNicknameResponse _$CheckNicknameResponseFromJson(
  Map<String, dynamic> json,
) => CheckNicknameResponse(
  success: json['success'] as bool,
  data: json['data'] == null
      ? null
      : CheckNicknameData.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'] as String?,
);

Map<String, dynamic> _$CheckNicknameResponseToJson(
  CheckNicknameResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'data': instance.data,
  'error': instance.error,
};

CheckNicknameData _$CheckNicknameDataFromJson(Map<String, dynamic> json) =>
    CheckNicknameData(available: json['available'] as bool);

Map<String, dynamic> _$CheckNicknameDataToJson(CheckNicknameData instance) =>
    <String, dynamic>{'available': instance.available};
