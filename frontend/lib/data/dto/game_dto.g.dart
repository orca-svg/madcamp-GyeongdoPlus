// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoveRequest _$MoveRequestFromJson(Map<String, dynamic> json) => MoveRequest(
  matchId: json['matchId'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  heartRate: (json['heartRate'] as num?)?.toInt(),
  heading: (json['heading'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MoveRequestToJson(MoveRequest instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'lat': instance.lat,
      'lng': instance.lng,
      'heartRate': instance.heartRate,
      'heading': instance.heading,
    };

ArrestRequest _$ArrestRequestFromJson(Map<String, dynamic> json) =>
    ArrestRequest(
      matchId: json['matchId'] as String,
      copId: json['copId'] as String?,
    );

Map<String, dynamic> _$ArrestRequestToJson(ArrestRequest instance) =>
    <String, dynamic>{'matchId': instance.matchId, 'copId': instance.copId};

RescueRequest _$RescueRequestFromJson(Map<String, dynamic> json) =>
    RescueRequest(matchId: json['matchId'] as String);

Map<String, dynamic> _$RescueRequestToJson(RescueRequest instance) =>
    <String, dynamic>{'matchId': instance.matchId};

AbilitySelectRequest _$AbilitySelectRequestFromJson(
  Map<String, dynamic> json,
) => AbilitySelectRequest(
  matchId: json['matchId'] as String,
  abilityClass: json['abilityClass'] as String,
);

Map<String, dynamic> _$AbilitySelectRequestToJson(
  AbilitySelectRequest instance,
) => <String, dynamic>{
  'matchId': instance.matchId,
  'abilityClass': instance.abilityClass,
};

AbilityUseRequest _$AbilityUseRequestFromJson(Map<String, dynamic> json) =>
    AbilityUseRequest(matchId: json['matchId'] as String);

Map<String, dynamic> _$AbilityUseRequestToJson(AbilityUseRequest instance) =>
    <String, dynamic>{'matchId': instance.matchId};

ItemSelectRequest _$ItemSelectRequestFromJson(Map<String, dynamic> json) =>
    ItemSelectRequest(
      matchId: json['matchId'] as String,
      itemId: json['itemId'] as String,
    );

Map<String, dynamic> _$ItemSelectRequestToJson(ItemSelectRequest instance) =>
    <String, dynamic>{'matchId': instance.matchId, 'itemId': instance.itemId};

ItemUseRequest _$ItemUseRequestFromJson(Map<String, dynamic> json) =>
    ItemUseRequest(
      matchId: json['matchId'] as String,
      itemId: json['itemId'] as String,
    );

Map<String, dynamic> _$ItemUseRequestToJson(ItemUseRequest instance) =>
    <String, dynamic>{'matchId': instance.matchId, 'itemId': instance.itemId};

MoveResponse _$MoveResponseFromJson(Map<String, dynamic> json) => MoveResponse(
  nearbyEvents: (json['nearbyEvents'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  autoArrestStatus: json['autoArrestStatus'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$MoveResponseToJson(MoveResponse instance) =>
    <String, dynamic>{
      'nearbyEvents': instance.nearbyEvents,
      'autoArrestStatus': instance.autoArrestStatus,
    };

ArrestResponse _$ArrestResponseFromJson(Map<String, dynamic> json) =>
    ArrestResponse(
      arrestedUser: json['arrestedUser'] as Map<String, dynamic>,
      prisonQueueIndex: (json['prisonQueueIndex'] as num).toInt(),
    );

Map<String, dynamic> _$ArrestResponseToJson(ArrestResponse instance) =>
    <String, dynamic>{
      'arrestedUser': instance.arrestedUser,
      'prisonQueueIndex': instance.prisonQueueIndex,
    };

RescueResponse _$RescueResponseFromJson(Map<String, dynamic> json) =>
    RescueResponse(
      rescuedUserIds: (json['rescuedUserIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      remainingPrisoners: (json['remainingPrisoners'] as num).toInt(),
    );

Map<String, dynamic> _$RescueResponseToJson(RescueResponse instance) =>
    <String, dynamic>{
      'rescuedUserIds': instance.rescuedUserIds,
      'remainingPrisoners': instance.remainingPrisoners,
    };

GameSyncResponse _$GameSyncResponseFromJson(Map<String, dynamic> json) =>
    GameSyncResponse(
      gameStatus: json['gameStatus'] as String,
      myState: json['myState'] as Map<String, dynamic>,
      prisonQueue: (json['prisonQueue'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$GameSyncResponseToJson(GameSyncResponse instance) =>
    <String, dynamic>{
      'gameStatus': instance.gameStatus,
      'myState': instance.myState,
      'prisonQueue': instance.prisonQueue,
    };

GameEndResponse _$GameEndResponseFromJson(Map<String, dynamic> json) =>
    GameEndResponse(
      winnerTeam: json['winnerTeam'] as String,
      mvpUser: json['mvpUser'] as Map<String, dynamic>?,
      resultReport: json['resultReport'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$GameEndResponseToJson(GameEndResponse instance) =>
    <String, dynamic>{
      'winnerTeam': instance.winnerTeam,
      'mvpUser': instance.mvpUser,
      'resultReport': instance.resultReport,
    };
