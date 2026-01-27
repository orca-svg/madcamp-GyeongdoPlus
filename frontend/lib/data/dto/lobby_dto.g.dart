// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateRoomRequest _$CreateRoomRequestFromJson(Map<String, dynamic> json) =>
    CreateRoomRequest(
      mode: json['mode'] as String,
      maxPlayers: (json['maxPlayers'] as num).toInt(),
      timeLimit: (json['timeLimit'] as num).toInt(),
      rules: json['rules'] as Map<String, dynamic>,
      mapConfig: json['mapConfig'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$CreateRoomRequestToJson(CreateRoomRequest instance) =>
    <String, dynamic>{
      'mode': instance.mode,
      'maxPlayers': instance.maxPlayers,
      'timeLimit': instance.timeLimit,
      'rules': instance.rules,
      'mapConfig': instance.mapConfig,
    };

JoinRoomRequest _$JoinRoomRequestFromJson(Map<String, dynamic> json) =>
    JoinRoomRequest(roomCode: json['roomCode'] as String);

Map<String, dynamic> _$JoinRoomRequestToJson(JoinRoomRequest instance) =>
    <String, dynamic>{'roomCode': instance.roomCode};

UpdateRoomRequest _$UpdateRoomRequestFromJson(Map<String, dynamic> json) =>
    UpdateRoomRequest(
      mode: json['mode'] as String?,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt(),
      timeLimit: (json['timeLimit'] as num?)?.toInt(),
      rules: json['rules'] as Map<String, dynamic>?,
      mapConfig: json['mapConfig'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UpdateRoomRequestToJson(UpdateRoomRequest instance) =>
    <String, dynamic>{
      'mode': instance.mode,
      'maxPlayers': instance.maxPlayers,
      'timeLimit': instance.timeLimit,
      'rules': instance.rules,
      'mapConfig': instance.mapConfig,
    };

KickUserRequest _$KickUserRequestFromJson(Map<String, dynamic> json) =>
    KickUserRequest(
      matchId: json['matchId'] as String,
      targetUserId: json['targetUserId'] as String,
    );

Map<String, dynamic> _$KickUserRequestToJson(KickUserRequest instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'targetUserId': instance.targetUserId,
    };

StartGameRequest _$StartGameRequestFromJson(Map<String, dynamic> json) =>
    StartGameRequest(matchId: json['matchId'] as String);

Map<String, dynamic> _$StartGameRequestToJson(StartGameRequest instance) =>
    <String, dynamic>{'matchId': instance.matchId};

CreateRoomResponse _$CreateRoomResponseFromJson(Map<String, dynamic> json) =>
    CreateRoomResponse(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : CreateRoomData.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$CreateRoomResponseToJson(CreateRoomResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };

CreateRoomData _$CreateRoomDataFromJson(Map<String, dynamic> json) =>
    CreateRoomData(
      matchId: json['matchId'] as String,
      roomCode: json['roomCode'] as String,
    );

Map<String, dynamic> _$CreateRoomDataToJson(CreateRoomData instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'roomCode': instance.roomCode,
    };

JoinRoomResponse _$JoinRoomResponseFromJson(Map<String, dynamic> json) =>
    JoinRoomResponse(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : JoinRoomData.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$JoinRoomResponseToJson(JoinRoomResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };

JoinRoomData _$JoinRoomDataFromJson(Map<String, dynamic> json) => JoinRoomData(
  matchId: json['matchId'] as String,
  myRole: json['myRole'] as String,
  hostId: json['hostId'] as String,
);

Map<String, dynamic> _$JoinRoomDataToJson(JoinRoomData instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'myRole': instance.myRole,
      'hostId': instance.hostId,
    };

RoomDetailResponse _$RoomDetailResponseFromJson(Map<String, dynamic> json) =>
    RoomDetailResponse(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : RoomDetailData.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$RoomDetailResponseToJson(RoomDetailResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'error': instance.error,
    };

RoomDetailData _$RoomDetailDataFromJson(Map<String, dynamic> json) =>
    RoomDetailData(
      players: (json['players'] as List<dynamic>)
          .map((e) => PlayerInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: json['settings'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$RoomDetailDataToJson(RoomDetailData instance) =>
    <String, dynamic>{
      'players': instance.players,
      'settings': instance.settings,
    };

PlayerInfo _$PlayerInfoFromJson(Map<String, dynamic> json) => PlayerInfo(
  userId: json['userId'] as String,
  nickname: json['nickname'] as String,
  team: json['team'] as String,
  isReady: json['isReady'] as bool,
  isHost: json['isHost'] as bool,
);

Map<String, dynamic> _$PlayerInfoToJson(PlayerInfo instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'nickname': instance.nickname,
      'team': instance.team,
      'isReady': instance.isReady,
      'isHost': instance.isHost,
    };
