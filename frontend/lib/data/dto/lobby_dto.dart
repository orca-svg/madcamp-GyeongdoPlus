import 'package:json_annotation/json_annotation.dart';

part 'lobby_dto.g.dart';

// ------------------------------------------------------------------
// Create Room
// ------------------------------------------------------------------

@JsonSerializable()
class CreateRoomDto {
  final String mode; // NORMAL, ITEM, ABILITY
  final int maxPlayers;
  final int timeLimit;
  final dynamic mapConfig; // JSON
  final dynamic rules; // JSON

  CreateRoomDto({
    required this.mode,
    required this.maxPlayers,
    required this.timeLimit,
    required this.mapConfig,
    required this.rules,
  });

  Map<String, dynamic> toJson() => _$CreateRoomDtoToJson(this);
}

@JsonSerializable()
class CreateRoomDataDto {
  final String matchId;
  final String roomCode;

  CreateRoomDataDto({required this.matchId, required this.roomCode});

  factory CreateRoomDataDto.fromJson(Map<String, dynamic> json) =>
      _$CreateRoomDataDtoFromJson(json);
}

@JsonSerializable()
class CreateRoomResponseDto {
  final bool? success;
  final String? message;
  final CreateRoomDataDto? data;
  final dynamic error;

  CreateRoomResponseDto({this.success, this.message, this.data, this.error});

  factory CreateRoomResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CreateRoomResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Join Room
// ------------------------------------------------------------------

@JsonSerializable()
class JoinRoomDto {
  final String roomCode;

  JoinRoomDto({required this.roomCode});

  Map<String, dynamic> toJson() => _$JoinRoomDtoToJson(this);
}

@JsonSerializable()
class JoinRoomDataDto {
  final String matchId;
  final String myRole;
  final String hostId;
  final dynamic mapConfig;

  JoinRoomDataDto({
    required this.matchId,
    required this.myRole,
    required this.hostId,
    required this.mapConfig,
  });

  factory JoinRoomDataDto.fromJson(Map<String, dynamic> json) =>
      _$JoinRoomDataDtoFromJson(json);
}

@JsonSerializable()
class JoinRoomResponseDto {
  final bool? success;
  final String? message;
  final JoinRoomDataDto? data;
  final dynamic error;

  JoinRoomResponseDto({this.success, this.message, this.data, this.error});

  factory JoinRoomResponseDto.fromJson(Map<String, dynamic> json) =>
      _$JoinRoomResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Kick User
// ------------------------------------------------------------------

@JsonSerializable()
class KickUserDto {
  final String matchId;
  final String targetUserId;

  KickUserDto({required this.matchId, required this.targetUserId});

  Map<String, dynamic> toJson() => _$KickUserDtoToJson(this);
}

@JsonSerializable()
class KickUserDataDto {
  final String kickedUserId;
  final int remainingPlayerCount;

  KickUserDataDto({
    required this.kickedUserId,
    required this.remainingPlayerCount,
  });

  factory KickUserDataDto.fromJson(Map<String, dynamic> json) =>
      _$KickUserDataDtoFromJson(json);
}

@JsonSerializable()
class KickUserResponseDto {
  final bool? success;
  final String? message;
  final KickUserDataDto? data;
  final dynamic error;

  KickUserResponseDto({this.success, this.message, this.data, this.error});

  factory KickUserResponseDto.fromJson(Map<String, dynamic> json) =>
      _$KickUserResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Get Room Details
// ------------------------------------------------------------------

@JsonSerializable()
class RoomSettingsDto {
  final String mode;
  final int timeLimit;
  final int maxPlayers;
  final dynamic mapConfig;
  final dynamic rules;

  RoomSettingsDto({
    required this.mode,
    required this.timeLimit,
    required this.maxPlayers,
    required this.mapConfig,
    this.rules,
  });

  factory RoomSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$RoomSettingsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RoomSettingsDtoToJson(this);
}

@JsonSerializable()
class RoomPlayerDto {
  final String userId;
  final String nickname;
  final bool ready;
  final String? team;

  RoomPlayerDto({
    required this.userId,
    required this.nickname,
    required this.ready,
    this.team,
  });

  factory RoomPlayerDto.fromJson(Map<String, dynamic> json) =>
      _$RoomPlayerDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RoomPlayerDtoToJson(this);
}

@JsonSerializable()
class RoomDetailsDataDto {
  final String matchId;
  final String status;
  final String hostId;
  final RoomSettingsDto settings;
  final List<RoomPlayerDto> players;

  RoomDetailsDataDto({
    required this.matchId,
    required this.status,
    required this.hostId,
    required this.settings,
    required this.players,
  });

  factory RoomDetailsDataDto.fromJson(Map<String, dynamic> json) =>
      _$RoomDetailsDataDtoFromJson(json);
}

@JsonSerializable()
class GetRoomDetailsResponseDto {
  final bool? success;
  final String? message;
  final RoomDetailsDataDto? data;
  final dynamic error;

  GetRoomDetailsResponseDto({
    this.success,
    this.message,
    this.data,
    this.error,
  });

  factory GetRoomDetailsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GetRoomDetailsResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Update Room
// ------------------------------------------------------------------

@JsonSerializable()
class UpdateRoomDto {
  final String? mode;
  final int? timeLimit;
  final dynamic mapConfig;

  UpdateRoomDto({this.mode, this.timeLimit, this.mapConfig});

  Map<String, dynamic> toJson() => _$UpdateRoomDtoToJson(this);
}

@JsonSerializable()
class UpdatedSettingsDto {
  final String mode;
  final int timeLimit;
  final dynamic mapConfig;
  final dynamic rules;

  UpdatedSettingsDto({
    required this.mode,
    required this.timeLimit,
    required this.mapConfig,
    this.rules,
  });

  factory UpdatedSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$UpdatedSettingsDtoFromJson(json);
}

@JsonSerializable()
class UpdateRoomDataDto {
  final String matchId;
  final UpdatedSettingsDto updatedSettings;

  UpdateRoomDataDto({required this.matchId, required this.updatedSettings});

  factory UpdateRoomDataDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateRoomDataDtoFromJson(json);
}

@JsonSerializable()
class UpdateRoomResponseDto {
  final bool? success;
  final String? message;
  final UpdateRoomDataDto? data;
  final dynamic error;

  UpdateRoomResponseDto({this.success, this.message, this.data, this.error});

  factory UpdateRoomResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateRoomResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Start Game
// ------------------------------------------------------------------

@JsonSerializable()
class StartGameDto {
  final String matchId;

  StartGameDto({required this.matchId});

  Map<String, dynamic> toJson() => _$StartGameDtoToJson(this);
}

@JsonSerializable()
class StartGameDataDto {
  final String matchId;
  final DateTime startTime;
  final int gameDuration;

  StartGameDataDto({
    required this.matchId,
    required this.startTime,
    required this.gameDuration,
  });

  factory StartGameDataDto.fromJson(Map<String, dynamic> json) =>
      _$StartGameDataDtoFromJson(json);
}

@JsonSerializable()
class StartGameResponseDto {
  final bool? success;
  final String? message;
  final StartGameDataDto? data;
  final dynamic error;

  StartGameResponseDto({this.success, this.message, this.data, this.error});

  factory StartGameResponseDto.fromJson(Map<String, dynamic> json) =>
      _$StartGameResponseDtoFromJson(json);
}
