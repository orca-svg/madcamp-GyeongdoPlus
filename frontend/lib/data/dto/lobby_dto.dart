import 'package:json_annotation/json_annotation.dart';

part 'lobby_dto.g.dart';

// ============================================================================
// Request DTOs
// ============================================================================

@JsonSerializable()
class CreateRoomRequest {
  final String mode;
  final int maxPlayers;
  final int timeLimit;
  final Map<String, dynamic> rules;
  final Map<String, dynamic> mapConfig;

  const CreateRoomRequest({
    required this.mode,
    required this.maxPlayers,
    required this.timeLimit,
    required this.rules,
    required this.mapConfig,
  });

  factory CreateRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateRoomRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRoomRequestToJson(this);
}

@JsonSerializable()
class JoinRoomRequest {
  final String roomCode;

  const JoinRoomRequest({required this.roomCode});

  factory JoinRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$JoinRoomRequestFromJson(json);

  Map<String, dynamic> toJson() => _$JoinRoomRequestToJson(this);
}

@JsonSerializable()
class UpdateRoomRequest {
  final String? mode;
  final int? maxPlayers;
  final int? timeLimit;
  final Map<String, dynamic>? rules;
  final Map<String, dynamic>? mapConfig;

  const UpdateRoomRequest({
    this.mode,
    this.maxPlayers,
    this.timeLimit,
    this.rules,
    this.mapConfig,
  });

  factory UpdateRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateRoomRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateRoomRequestToJson(this);
}

@JsonSerializable()
class KickUserRequest {
  final String matchId;
  final String targetUserId;

  const KickUserRequest({
    required this.matchId,
    required this.targetUserId,
  });

  factory KickUserRequest.fromJson(Map<String, dynamic> json) =>
      _$KickUserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$KickUserRequestToJson(this);
}

@JsonSerializable()
class StartGameRequest {
  final String matchId;

  const StartGameRequest({required this.matchId});

  factory StartGameRequest.fromJson(Map<String, dynamic> json) =>
      _$StartGameRequestFromJson(json);

  Map<String, dynamic> toJson() => _$StartGameRequestToJson(this);
}

// ============================================================================
// Response DTOs
// ============================================================================

@JsonSerializable()
class CreateRoomResponse {
  final bool success;
  final CreateRoomData? data;
  final String? error;

  const CreateRoomResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory CreateRoomResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateRoomResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRoomResponseToJson(this);
}

@JsonSerializable()
class CreateRoomData {
  final String matchId;
  final String roomCode;

  const CreateRoomData({
    required this.matchId,
    required this.roomCode,
  });

  factory CreateRoomData.fromJson(Map<String, dynamic> json) =>
      _$CreateRoomDataFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRoomDataToJson(this);
}

@JsonSerializable()
class JoinRoomResponse {
  final bool success;
  final JoinRoomData? data;
  final String? error;

  const JoinRoomResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory JoinRoomResponse.fromJson(Map<String, dynamic> json) =>
      _$JoinRoomResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JoinRoomResponseToJson(this);
}

@JsonSerializable()
class JoinRoomData {
  final String matchId;
  final String myRole;
  final String hostId;

  const JoinRoomData({
    required this.matchId,
    required this.myRole,
    required this.hostId,
  });

  factory JoinRoomData.fromJson(Map<String, dynamic> json) =>
      _$JoinRoomDataFromJson(json);

  Map<String, dynamic> toJson() => _$JoinRoomDataToJson(this);
}

@JsonSerializable()
class RoomDetailResponse {
  final bool success;
  final RoomDetailData? data;
  final String? error;

  const RoomDetailResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory RoomDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$RoomDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RoomDetailResponseToJson(this);
}

@JsonSerializable()
class RoomDetailData {
  final List<PlayerInfo> players;
  final Map<String, dynamic> settings;

  const RoomDetailData({
    required this.players,
    required this.settings,
  });

  factory RoomDetailData.fromJson(Map<String, dynamic> json) =>
      _$RoomDetailDataFromJson(json);

  Map<String, dynamic> toJson() => _$RoomDetailDataToJson(this);
}

@JsonSerializable()
class PlayerInfo {
  final String userId;
  final String nickname;
  final String team;
  final bool isReady;
  final bool isHost;

  const PlayerInfo({
    required this.userId,
    required this.nickname,
    required this.team,
    required this.isReady,
    required this.isHost,
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> json) =>
      _$PlayerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerInfoToJson(this);
}
