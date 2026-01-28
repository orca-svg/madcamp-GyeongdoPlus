// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoveDto _$MoveDtoFromJson(Map<String, dynamic> json) => MoveDto(
  matchId: json['matchId'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  heartRate: (json['heartRate'] as num?)?.toInt(),
  heading: (json['heading'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MoveDtoToJson(MoveDto instance) => <String, dynamic>{
  'matchId': instance.matchId,
  'lat': instance.lat,
  'lng': instance.lng,
  'heartRate': instance.heartRate,
  'heading': instance.heading,
};

NearbyObjectDto _$NearbyObjectDtoFromJson(Map<String, dynamic> json) =>
    NearbyObjectDto(
      type: json['type'] as String,
      userId: json['userId'] as String,
      distance: (json['distance'] as num).toDouble(),
    );

Map<String, dynamic> _$NearbyObjectDtoToJson(NearbyObjectDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'userId': instance.userId,
      'distance': instance.distance,
    };

AutoArrestStatusDto _$AutoArrestStatusDtoFromJson(Map<String, dynamic> json) =>
    AutoArrestStatusDto(
      targetId: json['targetId'] as String,
      status: json['status'] as String,
      progress: (json['progress'] as num).toDouble(),
    );

Map<String, dynamic> _$AutoArrestStatusDtoToJson(
  AutoArrestStatusDto instance,
) => <String, dynamic>{
  'targetId': instance.targetId,
  'status': instance.status,
  'progress': instance.progress,
};

MoveResponseDataDto _$MoveResponseDataDtoFromJson(Map<String, dynamic> json) =>
    MoveResponseDataDto(
      nearbyEvents: (json['nearbyEvents'] as List<dynamic>)
          .map((e) => NearbyObjectDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      autoArrestStatus: json['autoArrestStatus'] == null
          ? null
          : AutoArrestStatusDto.fromJson(
              json['autoArrestStatus'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$MoveResponseDataDtoToJson(
  MoveResponseDataDto instance,
) => <String, dynamic>{
  'nearbyEvents': instance.nearbyEvents,
  'autoArrestStatus': instance.autoArrestStatus,
};

MoveResponseDto _$MoveResponseDtoFromJson(Map<String, dynamic> json) =>
    MoveResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: MoveResponseDataDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$MoveResponseDtoToJson(MoveResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

ArrestDto _$ArrestDtoFromJson(Map<String, dynamic> json) => ArrestDto(
  matchId: json['matchId'] as String,
  copId: json['copId'] as String?,
  targetId: json['targetId'] as String?,
);

Map<String, dynamic> _$ArrestDtoToJson(ArrestDto instance) => <String, dynamic>{
  'matchId': instance.matchId,
  'copId': instance.copId,
  'targetId': instance.targetId,
};

ArrestDataDto _$ArrestDataDtoFromJson(Map<String, dynamic> json) =>
    ArrestDataDto(
      arrestedUser: json['arrestedUser'] as String,
      status: json['status'] as String,
      prisonQueueIndex: (json['prisonQueueIndex'] as num).toInt(),
    );

Map<String, dynamic> _$ArrestDataDtoToJson(ArrestDataDto instance) =>
    <String, dynamic>{
      'arrestedUser': instance.arrestedUser,
      'status': instance.status,
      'prisonQueueIndex': instance.prisonQueueIndex,
    };

ArrestResponseDto _$ArrestResponseDtoFromJson(Map<String, dynamic> json) =>
    ArrestResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: ArrestDataDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$ArrestResponseDtoToJson(ArrestResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

RescueDto _$RescueDtoFromJson(Map<String, dynamic> json) =>
    RescueDto(matchId: json['matchId'] as String);

Map<String, dynamic> _$RescueDtoToJson(RescueDto instance) => <String, dynamic>{
  'matchId': instance.matchId,
};

RescueDataDto _$RescueDataDtoFromJson(Map<String, dynamic> json) =>
    RescueDataDto(
      rescuedUserIds: (json['rescuedUserIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      rescueType: json['rescueType'] as String,
      remainingPrisoners: (json['remainingPrisoners'] as num).toInt(),
    );

Map<String, dynamic> _$RescueDataDtoToJson(RescueDataDto instance) =>
    <String, dynamic>{
      'rescuedUserIds': instance.rescuedUserIds,
      'rescueType': instance.rescueType,
      'remainingPrisoners': instance.remainingPrisoners,
    };

RescueResponseDto _$RescueResponseDtoFromJson(Map<String, dynamic> json) =>
    RescueResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: RescueDataDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$RescueResponseDtoToJson(RescueResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

SelectAbilityDto _$SelectAbilityDtoFromJson(Map<String, dynamic> json) =>
    SelectAbilityDto(
      matchId: json['matchId'] as String,
      abilityClass: json['abilityClass'] as String,
    );

Map<String, dynamic> _$SelectAbilityDtoToJson(SelectAbilityDto instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'abilityClass': instance.abilityClass,
    };

SelectAbilityResponseDto _$SelectAbilityResponseDtoFromJson(
  Map<String, dynamic> json,
) => SelectAbilityResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: json['data'],
  error: json['error'],
);

Map<String, dynamic> _$SelectAbilityResponseDtoToJson(
  SelectAbilityResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

UseAbilityDto _$UseAbilityDtoFromJson(Map<String, dynamic> json) =>
    UseAbilityDto(matchId: json['matchId'] as String);

Map<String, dynamic> _$UseAbilityDtoToJson(UseAbilityDto instance) =>
    <String, dynamic>{'matchId': instance.matchId};

UseAbilityResponseDto _$UseAbilityResponseDtoFromJson(
  Map<String, dynamic> json,
) => UseAbilityResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: json['data'],
  error: json['error'],
);

Map<String, dynamic> _$UseAbilityResponseDtoToJson(
  UseAbilityResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

SelectItemDto _$SelectItemDtoFromJson(Map<String, dynamic> json) =>
    SelectItemDto(
      matchId: json['matchId'] as String,
      itemId: json['itemId'] as String,
    );

Map<String, dynamic> _$SelectItemDtoToJson(SelectItemDto instance) =>
    <String, dynamic>{'matchId': instance.matchId, 'itemId': instance.itemId};

SelectItemResponseDto _$SelectItemResponseDtoFromJson(
  Map<String, dynamic> json,
) => SelectItemResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: json['data'],
  error: json['error'],
);

Map<String, dynamic> _$SelectItemResponseDtoToJson(
  SelectItemResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

UseItemDto _$UseItemDtoFromJson(Map<String, dynamic> json) => UseItemDto(
  matchId: json['matchId'] as String,
  itemId: json['itemId'] as String,
);

Map<String, dynamic> _$UseItemDtoToJson(UseItemDto instance) =>
    <String, dynamic>{'matchId': instance.matchId, 'itemId': instance.itemId};

UseItemResponseDto _$UseItemResponseDtoFromJson(Map<String, dynamic> json) =>
    UseItemResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'],
      error: json['error'],
    );

Map<String, dynamic> _$UseItemResponseDtoToJson(UseItemResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

ActiveEffectsDto _$ActiveEffectsDtoFromJson(Map<String, dynamic> json) =>
    ActiveEffectsDto(
      invisible: json['invisible'] as bool,
      stealth: json['stealth'] as bool,
      rescueBoost: json['rescueBoost'] as bool,
    );

Map<String, dynamic> _$ActiveEffectsDtoToJson(ActiveEffectsDto instance) =>
    <String, dynamic>{
      'invisible': instance.invisible,
      'stealth': instance.stealth,
      'rescueBoost': instance.rescueBoost,
    };

MyStateDto _$MyStateDtoFromJson(Map<String, dynamic> json) => MyStateDto(
  role: json['role'] as String,
  status: json['status'] as String,
  items: (json['items'] as List<dynamic>).map((e) => e as String).toList(),
  abilityGauge: (json['abilityGauge'] as num).toDouble(),
  activeEffects: ActiveEffectsDto.fromJson(
    json['activeEffects'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$MyStateDtoToJson(MyStateDto instance) =>
    <String, dynamic>{
      'role': instance.role,
      'status': instance.status,
      'items': instance.items,
      'abilityGauge': instance.abilityGauge,
      'activeEffects': instance.activeEffects,
    };

SyncGameDataDto _$SyncGameDataDtoFromJson(Map<String, dynamic> json) =>
    SyncGameDataDto(
      gameStatus: json['gameStatus'] as String,
      serverTime: json['serverTime'] as String,
      startTime: json['startTime'] as String,
      timeLimit: (json['timeLimit'] as num).toInt(),
      policeScore: (json['policeScore'] as num).toInt(),
      totalThiefCount: (json['totalThiefCount'] as num).toInt(),
      myState: MyStateDto.fromJson(json['myState'] as Map<String, dynamic>),
      prisonQueue: (json['prisonQueue'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      shrinkingRadius: (json['shrinkingRadius'] as num).toDouble(),
    );

Map<String, dynamic> _$SyncGameDataDtoToJson(SyncGameDataDto instance) =>
    <String, dynamic>{
      'gameStatus': instance.gameStatus,
      'serverTime': instance.serverTime,
      'startTime': instance.startTime,
      'timeLimit': instance.timeLimit,
      'policeScore': instance.policeScore,
      'totalThiefCount': instance.totalThiefCount,
      'myState': instance.myState,
      'prisonQueue': instance.prisonQueue,
      'shrinkingRadius': instance.shrinkingRadius,
    };

SyncGameResponseDto _$SyncGameResponseDtoFromJson(Map<String, dynamic> json) =>
    SyncGameResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: SyncGameDataDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$SyncGameResponseDtoToJson(
  SyncGameResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'error': instance.error,
};

EndGameDto _$EndGameDtoFromJson(Map<String, dynamic> json) =>
    EndGameDto(reason: json['reason'] as String?);

Map<String, dynamic> _$EndGameDtoToJson(EndGameDto instance) =>
    <String, dynamic>{'reason': instance.reason};

MvpUserDto _$MvpUserDtoFromJson(Map<String, dynamic> json) => MvpUserDto(
  userId: json['userId'] as String,
  nickname: json['nickname'] as String,
  profileImage: json['profileImage'] as String,
);

Map<String, dynamic> _$MvpUserDtoToJson(MvpUserDto instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'nickname': instance.nickname,
      'profileImage': instance.profileImage,
    };

ResultReportDto _$ResultReportDtoFromJson(Map<String, dynamic> json) =>
    ResultReportDto(
      totalCatch: (json['totalCatch'] as num).toInt(),
      totalDistance: (json['totalDistance'] as num).toDouble(),
    );

Map<String, dynamic> _$ResultReportDtoToJson(ResultReportDto instance) =>
    <String, dynamic>{
      'totalCatch': instance.totalCatch,
      'totalDistance': instance.totalDistance,
    };

EndGameDataDto _$EndGameDataDtoFromJson(Map<String, dynamic> json) =>
    EndGameDataDto(
      matchId: json['matchId'] as String,
      playTime: (json['playTime'] as num).toInt(),
      winnerTeam: json['winnerTeam'] as String,
      mvpUser: MvpUserDto.fromJson(json['mvpUser'] as Map<String, dynamic>),
      resultReport: ResultReportDto.fromJson(
        json['resultReport'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$EndGameDataDtoToJson(EndGameDataDto instance) =>
    <String, dynamic>{
      'matchId': instance.matchId,
      'playTime': instance.playTime,
      'winnerTeam': instance.winnerTeam,
      'mvpUser': instance.mvpUser,
      'resultReport': instance.resultReport,
    };

EndGameResponseDto _$EndGameResponseDtoFromJson(Map<String, dynamic> json) =>
    EndGameResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: EndGameDataDto.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$EndGameResponseDtoToJson(EndGameResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'error': instance.error,
    };

RematchResponseDto _$RematchResponseDtoFromJson(Map<String, dynamic> json) =>
    RematchResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'],
    );

Map<String, dynamic> _$RematchResponseDtoToJson(RematchResponseDto instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

DelegateHostDto _$DelegateHostDtoFromJson(Map<String, dynamic> json) =>
    DelegateHostDto(targetUserId: json['targetUserId'] as String);

Map<String, dynamic> _$DelegateHostDtoToJson(DelegateHostDto instance) =>
    <String, dynamic>{'targetUserId': instance.targetUserId};

DelegateHostResponseDto _$DelegateHostResponseDtoFromJson(
  Map<String, dynamic> json,
) => DelegateHostResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: json['data'],
);

Map<String, dynamic> _$DelegateHostResponseDtoToJson(
  DelegateHostResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

LeaveGameResponseDto _$LeaveGameResponseDtoFromJson(
  Map<String, dynamic> json,
) => LeaveGameResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: json['data'],
);

Map<String, dynamic> _$LeaveGameResponseDtoToJson(
  LeaveGameResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};
