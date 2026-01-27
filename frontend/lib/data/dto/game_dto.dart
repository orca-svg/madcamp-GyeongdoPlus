import 'package:json_annotation/json_annotation.dart';

part 'game_dto.g.dart';

// ------------------------------------------------------------------
// Game Move
// ------------------------------------------------------------------

@JsonSerializable()
class MoveDto {
  final String matchId;
  final double lat;
  final double lng;
  final int? heartRate;
  final double? heading;

  MoveDto({
    required this.matchId,
    required this.lat,
    required this.lng,
    this.heartRate,
    this.heading,
  });

  Map<String, dynamic> toJson() => _$MoveDtoToJson(this);
}

@JsonSerializable()
class NearbyObjectDto {
  final String type; // PLAYER, DECOY
  final String userId;
  final double distance;

  NearbyObjectDto({
    required this.type,
    required this.userId,
    required this.distance,
  });

  factory NearbyObjectDto.fromJson(Map<String, dynamic> json) =>
      _$NearbyObjectDtoFromJson(json);
}

@JsonSerializable()
class AutoArrestStatusDto {
  final String targetId;
  final String status; // PROGRESSING, COMPLETED
  final double progress;

  AutoArrestStatusDto({
    required this.targetId,
    required this.status,
    required this.progress,
  });

  factory AutoArrestStatusDto.fromJson(Map<String, dynamic> json) =>
      _$AutoArrestStatusDtoFromJson(json);
}

@JsonSerializable()
class MoveResponseDataDto {
  final List<NearbyObjectDto> nearbyEvents;
  final AutoArrestStatusDto? autoArrestStatus;

  MoveResponseDataDto({required this.nearbyEvents, this.autoArrestStatus});

  factory MoveResponseDataDto.fromJson(Map<String, dynamic> json) =>
      _$MoveResponseDataDtoFromJson(json);
}

@JsonSerializable()
class MoveResponseDto {
  final bool success;
  final String message;
  final MoveResponseDataDto data;
  final dynamic error;

  MoveResponseDto({
    required this.success,
    required this.message,
    required this.data,
    this.error,
  });

  factory MoveResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MoveResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Actions (Arrest, Rescue)
// ------------------------------------------------------------------

@JsonSerializable()
class ArrestDto {
  final String matchId;
  final String? copId;

  ArrestDto({required this.matchId, this.copId});

  Map<String, dynamic> toJson() => _$ArrestDtoToJson(this);
}

@JsonSerializable()
class ArrestDataDto {
  final String arrestedUser;
  final String status;
  final int prisonQueueIndex;

  ArrestDataDto({
    required this.arrestedUser,
    required this.status,
    required this.prisonQueueIndex,
  });

  factory ArrestDataDto.fromJson(Map<String, dynamic> json) =>
      _$ArrestDataDtoFromJson(json);
}

@JsonSerializable()
class ArrestResponseDto {
  final bool success;
  final String message;
  final ArrestDataDto data;
  final dynamic error;

  ArrestResponseDto({
    required this.success,
    required this.message,
    required this.data,
    this.error,
  });

  factory ArrestResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ArrestResponseDtoFromJson(json);
}

@JsonSerializable()
class RescueDto {
  final String matchId;

  RescueDto({required this.matchId});

  Map<String, dynamic> toJson() => _$RescueDtoToJson(this);
}

@JsonSerializable()
class RescueDataDto {
  final List<String> rescuedUserIds;
  final String rescueType;
  final int remainingPrisoners;

  RescueDataDto({
    required this.rescuedUserIds,
    required this.rescueType,
    required this.remainingPrisoners,
  });

  factory RescueDataDto.fromJson(Map<String, dynamic> json) =>
      _$RescueDataDtoFromJson(json);
}

@JsonSerializable()
class RescueResponseDto {
  final bool success;
  final String message;
  final RescueDataDto data;
  final dynamic error;

  RescueResponseDto({
    required this.success,
    required this.message,
    required this.data,
    this.error,
  });

  factory RescueResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RescueResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Ability / Item
// ------------------------------------------------------------------

@JsonSerializable()
class SelectAbilityDto {
  final String matchId;
  final String abilityClass;

  SelectAbilityDto({required this.matchId, required this.abilityClass});

  Map<String, dynamic> toJson() => _$SelectAbilityDtoToJson(this);
}

@JsonSerializable()
class SelectAbilityResponseDto {
  final bool success;
  final String message;
  final dynamic data;
  final dynamic error;

  SelectAbilityResponseDto({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory SelectAbilityResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SelectAbilityResponseDtoFromJson(json);
}

@JsonSerializable()
class UseAbilityDto {
  final String matchId;

  UseAbilityDto({required this.matchId});

  Map<String, dynamic> toJson() => _$UseAbilityDtoToJson(this);
}

@JsonSerializable()
class UseAbilityResponseDto {
  final bool success;
  final String message;
  final dynamic data;
  final dynamic error;

  UseAbilityResponseDto({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory UseAbilityResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UseAbilityResponseDtoFromJson(json);
}

@JsonSerializable()
class SelectItemDto {
  final String matchId;
  final String itemId;

  SelectItemDto({required this.matchId, required this.itemId});

  Map<String, dynamic> toJson() => _$SelectItemDtoToJson(this);
}

@JsonSerializable()
class SelectItemResponseDto {
  final bool success;
  final String message;
  final dynamic data;
  final dynamic error;

  SelectItemResponseDto({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory SelectItemResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SelectItemResponseDtoFromJson(json);
}

@JsonSerializable()
class UseItemDto {
  final String matchId;
  final String itemId;

  UseItemDto({required this.matchId, required this.itemId});

  Map<String, dynamic> toJson() => _$UseItemDtoToJson(this);
}

@JsonSerializable()
class UseItemResponseDto {
  final bool success;
  final String message;
  final dynamic data;
  final dynamic error;

  UseItemResponseDto({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory UseItemResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UseItemResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Sync
// ------------------------------------------------------------------

@JsonSerializable()
class ActiveEffectsDto {
  final bool invisible;
  final bool stealth;
  final bool rescueBoost;

  ActiveEffectsDto({
    required this.invisible,
    required this.stealth,
    required this.rescueBoost,
  });

  factory ActiveEffectsDto.fromJson(Map<String, dynamic> json) =>
      _$ActiveEffectsDtoFromJson(json);
}

@JsonSerializable()
class MyStateDto {
  final String role;
  final String status;
  final List<String> items;
  final double abilityGauge;
  final ActiveEffectsDto activeEffects;

  MyStateDto({
    required this.role,
    required this.status,
    required this.items,
    required this.abilityGauge,
    required this.activeEffects,
  });

  factory MyStateDto.fromJson(Map<String, dynamic> json) =>
      _$MyStateDtoFromJson(json);
}

@JsonSerializable()
class SyncGameDataDto {
  final String gameStatus;
  final String serverTime;
  final String startTime;
  final int timeLimit;
  final int policeScore;
  final int totalThiefCount;
  final MyStateDto myState;
  final List<String> prisonQueue;
  final double shrinkingRadius;

  SyncGameDataDto({
    required this.gameStatus,
    required this.serverTime,
    required this.startTime,
    required this.timeLimit,
    required this.policeScore,
    required this.totalThiefCount,
    required this.myState,
    required this.prisonQueue,
    required this.shrinkingRadius,
  });

  factory SyncGameDataDto.fromJson(Map<String, dynamic> json) =>
      _$SyncGameDataDtoFromJson(json);
}

@JsonSerializable()
class SyncGameResponseDto {
  final bool success;
  final String message;
  final SyncGameDataDto data;
  final dynamic error;

  SyncGameResponseDto({
    required this.success,
    required this.message,
    required this.data,
    this.error,
  });

  factory SyncGameResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SyncGameResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// End Game & Others
// ------------------------------------------------------------------

@JsonSerializable()
class EndGameDto {
  final String? reason;

  EndGameDto({this.reason});

  Map<String, dynamic> toJson() => _$EndGameDtoToJson(this);
}

@JsonSerializable()
class MvpUserDto {
  final String userId;
  final String nickname;
  final String profileImage;

  MvpUserDto({
    required this.userId,
    required this.nickname,
    required this.profileImage,
  });

  factory MvpUserDto.fromJson(Map<String, dynamic> json) =>
      _$MvpUserDtoFromJson(json);
}

@JsonSerializable()
class ResultReportDto {
  final int totalCatch;
  final double totalDistance;

  ResultReportDto({required this.totalCatch, required this.totalDistance});

  factory ResultReportDto.fromJson(Map<String, dynamic> json) =>
      _$ResultReportDtoFromJson(json);
}

@JsonSerializable()
class EndGameDataDto {
  final String matchId;
  final int playTime;
  final String winnerTeam;
  final MvpUserDto mvpUser;
  final ResultReportDto resultReport;

  EndGameDataDto({
    required this.matchId,
    required this.playTime,
    required this.winnerTeam,
    required this.mvpUser,
    required this.resultReport,
  });

  factory EndGameDataDto.fromJson(Map<String, dynamic> json) =>
      _$EndGameDataDtoFromJson(json);
}

@JsonSerializable()
class EndGameResponseDto {
  final bool success;
  final String message;
  final EndGameDataDto data;
  final dynamic error;

  EndGameResponseDto({
    required this.success,
    required this.message,
    required this.data,
    this.error,
  });

  factory EndGameResponseDto.fromJson(Map<String, dynamic> json) =>
      _$EndGameResponseDtoFromJson(json);
}

@JsonSerializable()
class RematchResponseDto {
  final bool success;
  final String message;
  final dynamic data;

  RematchResponseDto({required this.success, required this.message, this.data});

  factory RematchResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RematchResponseDtoFromJson(json);
}

@JsonSerializable()
class DelegateHostDto {
  final String targetUserId;

  DelegateHostDto({required this.targetUserId});

  Map<String, dynamic> toJson() => _$DelegateHostDtoToJson(this);
}

@JsonSerializable()
class DelegateHostResponseDto {
  final bool success;
  final String message;
  final dynamic data;

  DelegateHostResponseDto({
    required this.success,
    required this.message,
    this.data,
  });

  factory DelegateHostResponseDto.fromJson(Map<String, dynamic> json) =>
      _$DelegateHostResponseDtoFromJson(json);
}

@JsonSerializable()
class LeaveGameResponseDto {
  final bool success;
  final String message;
  final dynamic data;

  LeaveGameResponseDto({
    required this.success,
    required this.message,
    this.data,
  });

  factory LeaveGameResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LeaveGameResponseDtoFromJson(json);
}
