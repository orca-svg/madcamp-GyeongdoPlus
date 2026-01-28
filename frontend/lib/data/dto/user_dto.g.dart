// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserStatDto _$UserStatDtoFromJson(Map<String, dynamic> json) => UserStatDto(
  policeMmr: (json['policeMmr'] as num?)?.toInt(),
  thiefMmr: (json['thiefMmr'] as num?)?.toInt(),
  totalCatch: (json['totalCatch'] as num).toInt(),
  totalSurvival: (json['totalSurvival'] as num).toInt(),
  totalDistance: (json['totalDistance'] as num).toDouble(),
  integrityScore: (json['integrityScore'] as num?)?.toInt(),
  totalRelease: (json['totalRelease'] as num?)?.toInt(),
  totalMvpCount: (json['totalMvpCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserStatDtoToJson(UserStatDto instance) =>
    <String, dynamic>{
      'policeMmr': instance.policeMmr,
      'thiefMmr': instance.thiefMmr,
      'totalCatch': instance.totalCatch,
      'totalSurvival': instance.totalSurvival,
      'totalDistance': instance.totalDistance,
      'integrityScore': instance.integrityScore,
      'totalRelease': instance.totalRelease,
      'totalMvpCount': instance.totalMvpCount,
    };

AchievementDto _$AchievementDtoFromJson(Map<String, dynamic> json) =>
    AchievementDto(
      achieveId: json['achieveId'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );

Map<String, dynamic> _$AchievementDtoToJson(AchievementDto instance) =>
    <String, dynamic>{
      'achieveId': instance.achieveId,
      'earnedAt': instance.earnedAt.toIso8601String(),
    };

MyProfileDataDto _$MyProfileDataDtoFromJson(Map<String, dynamic> json) =>
    MyProfileDataDto(
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      stat: UserStatDto.fromJson(json['stat'] as Map<String, dynamic>),
      achievements: (json['achievements'] as List<dynamic>)
          .map((e) => AchievementDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MyProfileDataDtoToJson(MyProfileDataDto instance) =>
    <String, dynamic>{
      'user': instance.user,
      'stat': instance.stat,
      'achievements': instance.achievements,
    };

MyProfileResponseDto _$MyProfileResponseDtoFromJson(
  Map<String, dynamic> json,
) => MyProfileResponseDto(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : MyProfileDataDto.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$MyProfileResponseDtoToJson(
  MyProfileResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

OtherUserProfileDto _$OtherUserProfileDtoFromJson(Map<String, dynamic> json) =>
    OtherUserProfileDto(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      profileImage: json['profileImage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$OtherUserProfileDtoToJson(
  OtherUserProfileDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'nickname': instance.nickname,
  'profileImage': instance.profileImage,
  'createdAt': instance.createdAt.toIso8601String(),
};

OtherUserProfileDataDto _$OtherUserProfileDataDtoFromJson(
  Map<String, dynamic> json,
) => OtherUserProfileDataDto(
  user: OtherUserProfileDto.fromJson(json['user'] as Map<String, dynamic>),
  stat: UserStatDto.fromJson(json['stat'] as Map<String, dynamic>),
  achievements: (json['achievements'] as List<dynamic>)
      .map((e) => AchievementDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OtherUserProfileDataDtoToJson(
  OtherUserProfileDataDto instance,
) => <String, dynamic>{
  'user': instance.user,
  'stat': instance.stat,
  'achievements': instance.achievements,
};

OtherProfileResponseDto _$OtherProfileResponseDtoFromJson(
  Map<String, dynamic> json,
) => OtherProfileResponseDto(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : OtherUserProfileDataDto.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$OtherProfileResponseDtoToJson(
  OtherProfileResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

UpdateProfileDto _$UpdateProfileDtoFromJson(Map<String, dynamic> json) =>
    UpdateProfileDto(
      nickname: json['nickname'] as String?,
      profileImage: json['profileImage'] as String?,
    );

Map<String, dynamic> _$UpdateProfileDtoToJson(UpdateProfileDto instance) =>
    <String, dynamic>{
      'nickname': instance.nickname,
      'profileImage': instance.profileImage,
    };

UpdateProfileDataDto _$UpdateProfileDataDtoFromJson(
  Map<String, dynamic> json,
) => UpdateProfileDataDto(
  nickname: json['nickname'] as String,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UpdateProfileDataDtoToJson(
  UpdateProfileDataDto instance,
) => <String, dynamic>{
  'nickname': instance.nickname,
  'updatedAt': instance.updatedAt.toIso8601String(),
};

UpdateProfileResponseDto _$UpdateProfileResponseDtoFromJson(
  Map<String, dynamic> json,
) => UpdateProfileResponseDto(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : UpdateProfileDataDto.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$UpdateProfileResponseDtoToJson(
  UpdateProfileResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

MatchHistoryQueryDto _$MatchHistoryQueryDtoFromJson(
  Map<String, dynamic> json,
) => MatchHistoryQueryDto(
  page: (json['page'] as num?)?.toInt() ?? 1,
  limit: (json['limit'] as num?)?.toInt() ?? 10,
);

Map<String, dynamic> _$MatchHistoryQueryDtoToJson(
  MatchHistoryQueryDto instance,
) => <String, dynamic>{'page': instance.page, 'limit': instance.limit};

MyStatDto _$MyStatDtoFromJson(Map<String, dynamic> json) => MyStatDto(
  catchCount: (json['catchCount'] as num).toInt(),
  contribution: (json['contribution'] as num).toInt(),
);

Map<String, dynamic> _$MyStatDtoToJson(MyStatDto instance) => <String, dynamic>{
  'catchCount': instance.catchCount,
  'contribution': instance.contribution,
};

MapConfigDto _$MapConfigDtoFromJson(Map<String, dynamic> json) =>
    MapConfigDto(polygon: json['polygon'] as List<dynamic>, jail: json['jail']);

Map<String, dynamic> _$MapConfigDtoToJson(MapConfigDto instance) =>
    <String, dynamic>{'polygon': instance.polygon, 'jail': instance.jail};

GameRulesDto _$GameRulesDtoFromJson(Map<String, dynamic> json) => GameRulesDto(
  contactMode: json['contactMode'] as String,
  captureRule: json['captureRule'],
  jailRule: json['jailRule'],
);

Map<String, dynamic> _$GameRulesDtoToJson(GameRulesDto instance) =>
    <String, dynamic>{
      'contactMode': instance.contactMode,
      'captureRule': instance.captureRule,
      'jailRule': instance.jailRule,
    };

GameInfoDto _$GameInfoDtoFromJson(Map<String, dynamic> json) => GameInfoDto(
  maxPlayers: (json['maxPlayers'] as num).toInt(),
  timeLimit: (json['timeLimit'] as num).toInt(),
  mapConfig: MapConfigDto.fromJson(json['mapConfig'] as Map<String, dynamic>),
  playTime: (json['playTime'] as num).toInt(),
  playedAt: DateTime.parse(json['playedAt'] as String),
  rules: GameRulesDto.fromJson(json['rules'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GameInfoDtoToJson(GameInfoDto instance) =>
    <String, dynamic>{
      'maxPlayers': instance.maxPlayers,
      'timeLimit': instance.timeLimit,
      'mapConfig': instance.mapConfig,
      'playTime': instance.playTime,
      'playedAt': instance.playedAt.toIso8601String(),
      'rules': instance.rules,
    };

MatchRecordDto _$MatchRecordDtoFromJson(Map<String, dynamic> json) =>
    MatchRecordDto(
      matchId: json['matchId'] as String,
      result: json['result'] as String,
      role: json['role'] as String,
      myStat: MyStatDto.fromJson(json['myStat'] as Map<String, dynamic>),
      gameInfo: GameInfoDto.fromJson(json['gameInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MatchRecordDtoToJson(MatchRecordDto instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'result': instance.result,
      'role': instance.role,
      'myStat': instance.myStat,
      'gameInfo': instance.gameInfo,
    };

MatchHistoryResponseDto _$MatchHistoryResponseDtoFromJson(
  Map<String, dynamic> json,
) => MatchHistoryResponseDto(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>?)
      ?.map((e) => MatchRecordDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  error: json['error'],
);

Map<String, dynamic> _$MatchHistoryResponseDtoToJson(
  MatchHistoryResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

DeleteAccountDto _$DeleteAccountDtoFromJson(Map<String, dynamic> json) =>
    DeleteAccountDto(
      reason: json['reason'] as String?,
      agreedToLoseData: json['agreedToLoseData'] as bool,
    );

Map<String, dynamic> _$DeleteAccountDtoToJson(DeleteAccountDto instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'agreedToLoseData': instance.agreedToLoseData,
    };

DeleteAccountResponseDto _$DeleteAccountResponseDtoFromJson(
  Map<String, dynamic> json,
) => DeleteAccountResponseDto(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: json['data'],
  error: json['error'],
);

Map<String, dynamic> _$DeleteAccountResponseDtoToJson(
  DeleteAccountResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};
