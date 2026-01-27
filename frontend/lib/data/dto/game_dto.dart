import 'package:json_annotation/json_annotation.dart';

part 'game_dto.g.dart';

// ============================================================================
// Request DTOs
// ============================================================================

@JsonSerializable()
class MoveRequest {
  final String matchId;
  final double lat;
  final double lng;
  final int? heartRate;
  final double? heading;

  const MoveRequest({
    required this.matchId,
    required this.lat,
    required this.lng,
    this.heartRate,
    this.heading,
  });

  factory MoveRequest.fromJson(Map<String, dynamic> json) =>
      _$MoveRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MoveRequestToJson(this);
}

@JsonSerializable()
class ArrestRequest {
  final String matchId;
  final String? copId;

  const ArrestRequest({
    required this.matchId,
    this.copId,
  });

  factory ArrestRequest.fromJson(Map<String, dynamic> json) =>
      _$ArrestRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ArrestRequestToJson(this);
}

@JsonSerializable()
class RescueRequest {
  final String matchId;

  const RescueRequest({required this.matchId});

  factory RescueRequest.fromJson(Map<String, dynamic> json) =>
      _$RescueRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RescueRequestToJson(this);
}

@JsonSerializable()
class AbilitySelectRequest {
  final String matchId;
  final String abilityClass;

  const AbilitySelectRequest({
    required this.matchId,
    required this.abilityClass,
  });

  factory AbilitySelectRequest.fromJson(Map<String, dynamic> json) =>
      _$AbilitySelectRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AbilitySelectRequestToJson(this);
}

@JsonSerializable()
class AbilityUseRequest {
  final String matchId;

  const AbilityUseRequest({required this.matchId});

  factory AbilityUseRequest.fromJson(Map<String, dynamic> json) =>
      _$AbilityUseRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AbilityUseRequestToJson(this);
}

@JsonSerializable()
class ItemSelectRequest {
  final String matchId;
  final String itemId;

  const ItemSelectRequest({
    required this.matchId,
    required this.itemId,
  });

  factory ItemSelectRequest.fromJson(Map<String, dynamic> json) =>
      _$ItemSelectRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ItemSelectRequestToJson(this);
}

@JsonSerializable()
class ItemUseRequest {
  final String matchId;
  final String itemId;

  const ItemUseRequest({
    required this.matchId,
    required this.itemId,
  });

  factory ItemUseRequest.fromJson(Map<String, dynamic> json) =>
      _$ItemUseRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ItemUseRequestToJson(this);
}

// ============================================================================
// Response DTOs
// ============================================================================

@JsonSerializable()
class MoveResponse {
  final List<Map<String, dynamic>>? nearbyEvents;
  final Map<String, dynamic>? autoArrestStatus;

  const MoveResponse({
    this.nearbyEvents,
    this.autoArrestStatus,
  });

  factory MoveResponse.fromJson(Map<String, dynamic> json) =>
      _$MoveResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MoveResponseToJson(this);
}

@JsonSerializable()
class ArrestResponse {
  final Map<String, dynamic> arrestedUser;
  final int prisonQueueIndex;

  const ArrestResponse({
    required this.arrestedUser,
    required this.prisonQueueIndex,
  });

  factory ArrestResponse.fromJson(Map<String, dynamic> json) =>
      _$ArrestResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ArrestResponseToJson(this);
}

@JsonSerializable()
class RescueResponse {
  final List<String> rescuedUserIds;
  final int remainingPrisoners;

  const RescueResponse({
    required this.rescuedUserIds,
    required this.remainingPrisoners,
  });

  factory RescueResponse.fromJson(Map<String, dynamic> json) =>
      _$RescueResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RescueResponseToJson(this);
}

@JsonSerializable()
class GameSyncResponse {
  final String gameStatus;
  final Map<String, dynamic> myState;
  final List<Map<String, dynamic>> prisonQueue;

  const GameSyncResponse({
    required this.gameStatus,
    required this.myState,
    required this.prisonQueue,
  });

  factory GameSyncResponse.fromJson(Map<String, dynamic> json) =>
      _$GameSyncResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GameSyncResponseToJson(this);
}

@JsonSerializable()
class GameEndResponse {
  final String winnerTeam;
  final Map<String, dynamic>? mvpUser;
  final Map<String, dynamic> resultReport;

  const GameEndResponse({
    required this.winnerTeam,
    this.mvpUser,
    required this.resultReport,
  });

  factory GameEndResponse.fromJson(Map<String, dynamic> json) =>
      _$GameEndResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GameEndResponseToJson(this);
}
