import 'package:json_annotation/json_annotation.dart';
import 'auth_dto.dart'; // UserDto

part 'user_dto.g.dart';

// ------------------------------------------------------------------
// My Profile
// ------------------------------------------------------------------

@JsonSerializable()
class UserStatDto {
  final int? policeMmr;
  final int? thiefMmr;
  final int totalCatch;
  final int totalSurvival;
  final double totalDistance;
  final int? integrityScore;
  final int? totalRelease;
  final int? totalMvpCount;

  UserStatDto({
    this.policeMmr,
    this.thiefMmr,
    required this.totalCatch,
    required this.totalSurvival,
    required this.totalDistance,
    this.integrityScore,
    this.totalRelease,
    this.totalMvpCount,
  });

  factory UserStatDto.fromJson(Map<String, dynamic> json) =>
      _$UserStatDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatDtoToJson(this);
}

@JsonSerializable()
class AchievementDto {
  final String achieveId;
  final DateTime earnedAt;

  AchievementDto({required this.achieveId, required this.earnedAt});

  factory AchievementDto.fromJson(Map<String, dynamic> json) =>
      _$AchievementDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementDtoToJson(this);
}

@JsonSerializable()
class MyProfileDataDto {
  final UserDto user;
  final UserStatDto stat;
  final List<AchievementDto> achievements;

  MyProfileDataDto({
    required this.user,
    required this.stat,
    required this.achievements,
  });

  factory MyProfileDataDto.fromJson(Map<String, dynamic> json) =>
      _$MyProfileDataDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MyProfileDataDtoToJson(this);
}

@JsonSerializable()
class MyProfileResponseDto {
  final bool? success;
  final String? message;
  final MyProfileDataDto? data;
  final dynamic error;

  MyProfileResponseDto({this.success, this.message, this.data, this.error});

  factory MyProfileResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MyProfileResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Other Profile
// ------------------------------------------------------------------

@JsonSerializable()
class OtherUserProfileDto {
  final String id;
  final String nickname;
  final String? profileImage;
  final DateTime createdAt;

  OtherUserProfileDto({
    required this.id,
    required this.nickname,
    this.profileImage,
    required this.createdAt,
  });

  factory OtherUserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$OtherUserProfileDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OtherUserProfileDtoToJson(this);
}

@JsonSerializable()
class OtherUserProfileDataDto {
  final OtherUserProfileDto user;
  final UserStatDto stat;
  final List<AchievementDto> achievements;

  OtherUserProfileDataDto({
    required this.user,
    required this.stat,
    required this.achievements,
  });

  factory OtherUserProfileDataDto.fromJson(Map<String, dynamic> json) =>
      _$OtherUserProfileDataDtoFromJson(json);
}

@JsonSerializable()
class OtherProfileResponseDto {
  final bool? success;
  final String? message;
  final OtherUserProfileDataDto? data;
  final dynamic error;

  OtherProfileResponseDto({this.success, this.message, this.data, this.error});

  factory OtherProfileResponseDto.fromJson(Map<String, dynamic> json) =>
      _$OtherProfileResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Update Profile
// ------------------------------------------------------------------

@JsonSerializable()
class UpdateProfileDto {
  final String? nickname;
  final String? profileImage;

  UpdateProfileDto({this.nickname, this.profileImage});

  Map<String, dynamic> toJson() => _$UpdateProfileDtoToJson(this);
}

@JsonSerializable()
class UpdateProfileDataDto {
  final String nickname;
  final DateTime updatedAt;

  UpdateProfileDataDto({required this.nickname, required this.updatedAt});

  factory UpdateProfileDataDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileDataDtoFromJson(json);
}

@JsonSerializable()
class UpdateProfileResponseDto {
  final bool? success;
  final String? message;
  final UpdateProfileDataDto? data;
  final dynamic error;

  UpdateProfileResponseDto({this.success, this.message, this.data, this.error});

  factory UpdateProfileResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Match History
// ------------------------------------------------------------------

@JsonSerializable()
class MatchHistoryQueryDto {
  final int page;
  final int limit;

  MatchHistoryQueryDto({this.page = 1, this.limit = 10});

  Map<String, dynamic> toJson() => _$MatchHistoryQueryDtoToJson(this);
}

@JsonSerializable()
class MyStatDto {
  final int catchCount;
  final int? rescueCount; // Added for Thief stats
  final int contribution;

  MyStatDto({
    required this.catchCount,
    this.rescueCount,
    required this.contribution,
  });

  factory MyStatDto.fromJson(Map<String, dynamic> json) =>
      _$MyStatDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MyStatDtoToJson(this);
}

@JsonSerializable()
class MapConfigDto {
  final List<dynamic> polygon; // Or specific PointDto
  final dynamic jail; // Or JailDto

  MapConfigDto({required this.polygon, required this.jail});

  factory MapConfigDto.fromJson(Map<String, dynamic> json) =>
      _$MapConfigDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MapConfigDtoToJson(this);
}

@JsonSerializable()
class GameRulesDto {
  final String contactMode;
  final dynamic captureRule;
  final dynamic jailRule;

  GameRulesDto({
    required this.contactMode,
    required this.captureRule,
    required this.jailRule,
  });

  factory GameRulesDto.fromJson(Map<String, dynamic> json) =>
      _$GameRulesDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GameRulesDtoToJson(this);
}

@JsonSerializable()
class GameInfoDto {
  final int maxPlayers;
  final int timeLimit;
  final MapConfigDto mapConfig;
  final int playTime;
  final DateTime playedAt;
  final GameRulesDto rules;

  GameInfoDto({
    required this.maxPlayers,
    required this.timeLimit,
    required this.mapConfig,
    required this.playTime,
    required this.playedAt,
    required this.rules,
  });

  factory GameInfoDto.fromJson(Map<String, dynamic> json) =>
      _$GameInfoDtoFromJson(json);
  Map<String, dynamic> toJson() => _$GameInfoDtoToJson(this);
}

@JsonSerializable()
class MatchRecordDto {
  final String matchId;
  final String result; // WIN, LOSE, DRAW
  final String role; // POLICE, THIEF
  final MyStatDto myStat;
  final GameInfoDto gameInfo;

  MatchRecordDto({
    required this.matchId,
    required this.result,
    required this.role,
    required this.myStat,
    required this.gameInfo,
  });

  factory MatchRecordDto.fromJson(Map<String, dynamic> json) =>
      _$MatchRecordDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MatchRecordDtoToJson(this);
}

@JsonSerializable()
class MatchHistoryResponseDto {
  final bool? success;
  final String? message;
  final List<MatchRecordDto>? data;
  final dynamic error;

  MatchHistoryResponseDto({this.success, this.message, this.data, this.error});

  factory MatchHistoryResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MatchHistoryResponseDtoFromJson(json);
}

// ------------------------------------------------------------------
// Delete Account
// ------------------------------------------------------------------

@JsonSerializable()
class DeleteAccountDto {
  final String? reason;
  final bool agreedToLoseData;

  DeleteAccountDto({this.reason, required this.agreedToLoseData});

  Map<String, dynamic> toJson() => _$DeleteAccountDtoToJson(this);
}

@JsonSerializable()
class DeleteAccountResponseDto {
  final bool? success;
  final String? message;
  final dynamic data;
  final dynamic error;

  DeleteAccountResponseDto({this.success, this.message, this.data, this.error});

  factory DeleteAccountResponseDto.fromJson(Map<String, dynamic> json) =>
      _$DeleteAccountResponseDtoFromJson(json);
}
