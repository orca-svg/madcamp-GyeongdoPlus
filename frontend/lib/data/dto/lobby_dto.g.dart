// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateRoomDto _$CreateRoomDtoFromJson(Map<String, dynamic> json) =>
    CreateRoomDto(
      mode: json['mode'] as String,
      maxPlayers: (json['maxPlayers'] as num).toInt(),
      timeLimit: (json['timeLimit'] as num).toInt(),
      mapConfig: json['mapConfig'],
      rules: json['rules'],
    );

Map<String, dynamic> _$CreateRoomDtoToJson(CreateRoomDto instance) =>
    <String, dynamic>{
      'mode': instance.mode,
      'maxPlayers': instance.maxPlayers,
      'timeLimit': instance.timeLimit,
      'mapConfig': instance.mapConfig,
      'rules': instance.rules,
    };

CreateRoomDataDto _$CreateRoomDataDtoFromJson(Map<String, dynamic> json) =>
    CreateRoomDataDto(
      matchId: json['matchId'] as String,
      roomCode: json['roomCode'] as String,
    );

Map<String, dynamic> _$CreateRoomDataDtoToJson(CreateRoomDataDto instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'roomCode': instance.roomCode,
    };

CreateRoomResponseDto _$CreateRoomResponseDtoFromJson(
  Map<String, dynamic> json,
) => CreateRoomResponseDto(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : CreateRoomDataDto.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$CreateRoomResponseDtoToJson(
  CreateRoomResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

JoinRoomDto _$JoinRoomDtoFromJson(Map<String, dynamic> json) =>
    JoinRoomDto(roomCode: json['roomCode'] as String);

Map<String, dynamic> _$JoinRoomDtoToJson(JoinRoomDto instance) =>
    <String, dynamic>{'roomCode': instance.roomCode};

JoinRoomDataDto _$JoinRoomDataDtoFromJson(Map<String, dynamic> json) =>
    JoinRoomDataDto(
      matchId: json['matchId'] as String,
      myRole: json['myRole'] as String,
      hostId: json['hostId'] as String,
      mapConfig: json['mapConfig'],
    );

Map<String, dynamic> _$JoinRoomDataDtoToJson(JoinRoomDataDto instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'myRole': instance.myRole,
      'hostId': instance.hostId,
      'mapConfig': instance.mapConfig,
    };

JoinRoomResponseDto _$JoinRoomResponseDtoFromJson(Map<String, dynamic> json) =>
    JoinRoomResponseDto(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : JoinRoomDataDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$JoinRoomResponseDtoToJson(
  JoinRoomResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

KickUserDto _$KickUserDtoFromJson(Map<String, dynamic> json) => KickUserDto(
  matchId: json['matchId'] as String,
  targetUserId: json['targetUserId'] as String,
);

Map<String, dynamic> _$KickUserDtoToJson(KickUserDto instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'targetUserId': instance.targetUserId,
    };

KickUserDataDto _$KickUserDataDtoFromJson(Map<String, dynamic> json) =>
    KickUserDataDto(
      kickedUserId: json['kickedUserId'] as String,
      remainingPlayerCount: (json['remainingPlayerCount'] as num).toInt(),
    );

Map<String, dynamic> _$KickUserDataDtoToJson(KickUserDataDto instance) =>
    <String, dynamic>{
      'kickedUserId': instance.kickedUserId,
      'remainingPlayerCount': instance.remainingPlayerCount,
    };

KickUserResponseDto _$KickUserResponseDtoFromJson(Map<String, dynamic> json) =>
    KickUserResponseDto(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : KickUserDataDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$KickUserResponseDtoToJson(
  KickUserResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

RoomSettingsDto _$RoomSettingsDtoFromJson(Map<String, dynamic> json) =>
    RoomSettingsDto(
      mode: json['mode'] as String,
      timeLimit: (json['timeLimit'] as num).toInt(),
      maxPlayers: (json['maxPlayers'] as num).toInt(),
      mapConfig: json['mapConfig'],
      rules: json['rules'],
    );

Map<String, dynamic> _$RoomSettingsDtoToJson(RoomSettingsDto instance) =>
    <String, dynamic>{
      'mode': instance.mode,
      'timeLimit': instance.timeLimit,
      'maxPlayers': instance.maxPlayers,
      'mapConfig': instance.mapConfig,
      'rules': instance.rules,
    };

RoomPlayerDto _$RoomPlayerDtoFromJson(Map<String, dynamic> json) =>
    RoomPlayerDto(
      userId: json['userId'] as String,
      nickname: json['nickname'] as String,
      ready: json['ready'] as bool,
      team: json['team'] as String?,
    );

Map<String, dynamic> _$RoomPlayerDtoToJson(RoomPlayerDto instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'nickname': instance.nickname,
      'ready': instance.ready,
      'team': instance.team,
    };

RoomDetailsDataDto _$RoomDetailsDataDtoFromJson(Map<String, dynamic> json) =>
    RoomDetailsDataDto(
      matchId: json['matchId'] as String,
      status: json['status'] as String,
      hostId: json['hostId'] as String,
      settings: RoomSettingsDto.fromJson(
        json['settings'] as Map<String, dynamic>,
      ),
      players: (json['players'] as List<dynamic>)
          .map((e) => RoomPlayerDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RoomDetailsDataDtoToJson(RoomDetailsDataDto instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'status': instance.status,
      'hostId': instance.hostId,
      'settings': instance.settings,
      'players': instance.players,
    };

GetRoomDetailsResponseDto _$GetRoomDetailsResponseDtoFromJson(
  Map<String, dynamic> json,
) => GetRoomDetailsResponseDto(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : RoomDetailsDataDto.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$GetRoomDetailsResponseDtoToJson(
  GetRoomDetailsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

UpdateRoomDto _$UpdateRoomDtoFromJson(Map<String, dynamic> json) =>
    UpdateRoomDto(
      mode: json['mode'] as String?,
      timeLimit: (json['timeLimit'] as num?)?.toInt(),
      mapConfig: json['mapConfig'],
    );

Map<String, dynamic> _$UpdateRoomDtoToJson(UpdateRoomDto instance) =>
    <String, dynamic>{
      'mode': instance.mode,
      'timeLimit': instance.timeLimit,
      'mapConfig': instance.mapConfig,
    };

UpdatedSettingsDto _$UpdatedSettingsDtoFromJson(Map<String, dynamic> json) =>
    UpdatedSettingsDto(
      mode: json['mode'] as String,
      timeLimit: (json['timeLimit'] as num).toInt(),
      mapConfig: json['mapConfig'],
      rules: json['rules'],
    );

Map<String, dynamic> _$UpdatedSettingsDtoToJson(UpdatedSettingsDto instance) =>
    <String, dynamic>{
      'mode': instance.mode,
      'timeLimit': instance.timeLimit,
      'mapConfig': instance.mapConfig,
      'rules': instance.rules,
    };

UpdateRoomDataDto _$UpdateRoomDataDtoFromJson(Map<String, dynamic> json) =>
    UpdateRoomDataDto(
      matchId: json['matchId'] as String,
      updatedSettings: UpdatedSettingsDto.fromJson(
        json['updatedSettings'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$UpdateRoomDataDtoToJson(UpdateRoomDataDto instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'updatedSettings': instance.updatedSettings,
    };

UpdateRoomResponseDto _$UpdateRoomResponseDtoFromJson(
  Map<String, dynamic> json,
) => UpdateRoomResponseDto(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : UpdateRoomDataDto.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$UpdateRoomResponseDtoToJson(
  UpdateRoomResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

StartGameDto _$StartGameDtoFromJson(Map<String, dynamic> json) =>
    StartGameDto(matchId: json['matchId'] as String);

Map<String, dynamic> _$StartGameDtoToJson(StartGameDto instance) =>
    <String, dynamic>{'matchId': instance.matchId};

StartGameDataDto _$StartGameDataDtoFromJson(Map<String, dynamic> json) =>
    StartGameDataDto(
      matchId: json['matchId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      gameDuration: (json['gameDuration'] as num).toInt(),
    );

Map<String, dynamic> _$StartGameDataDtoToJson(StartGameDataDto instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'startTime': instance.startTime.toIso8601String(),
      'gameDuration': instance.gameDuration,
    };

StartGameResponseDto _$StartGameResponseDtoFromJson(
  Map<String, dynamic> json,
) => StartGameResponseDto(
  success: json['success'] as bool?,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : StartGameDataDto.fromJson(json['data'] as Map<String, dynamic>),
  error: json['error'],
);

Map<String, dynamic> _$StartGameResponseDtoToJson(
  StartGameResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};
