class MatchStateDto {
  final String matchId;
  final String state; // 'LOBBY' | 'PREP' | 'RUNNING' | 'ENDED'
  final String mode; // 'NORMAL' | 'ITEM' | 'ABILITY'
  final MatchRulesDto rules;
  final MatchTimeDto time;
  final MatchTeamsDto teams;
  final Map<String, MatchPlayerDto> players;
  final MatchLiveDto live;
  final MatchArenaDto? arena;

  const MatchStateDto({
    required this.matchId,
    required this.state,
    required this.mode,
    required this.rules,
    required this.time,
    required this.teams,
    required this.players,
    required this.live,
    required this.arena,
  });

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'state': state,
        'mode': mode,
        'rules': rules.toJson(),
        'time': time.toJson(),
        'teams': teams.toJson(),
        'players': {for (final e in players.entries) e.key: e.value.toJson()},
        'live': live.toJson(),
        if (arena != null) 'arena': arena!.toJson(),
      };

  factory MatchStateDto.fromJson(Map<String, dynamic> json) {
    final playersRaw = (json['players'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final stateRaw = (json['state'] ?? 'LOBBY').toString().toUpperCase();
    final validStates = {'LOBBY', 'PREP', 'RUNNING', 'ENDED'};
    final state = validStates.contains(stateRaw) ? stateRaw : 'LOBBY';

    return MatchStateDto(
      matchId: (json['matchId'] ?? '').toString(),
      state: state,
      mode: (json['mode'] ?? '').toString(),
      rules: MatchRulesDto.fromJson((json['rules'] as Map? ?? const {}).cast<String, dynamic>()),
      time: MatchTimeDto.fromJson((json['time'] as Map? ?? const {}).cast<String, dynamic>()),
      teams: MatchTeamsDto.fromJson((json['teams'] as Map? ?? const {}).cast<String, dynamic>()),
      players: {
        for (final e in playersRaw.entries)
          e.key: MatchPlayerDto.fromJson((e.value as Map? ?? const {}).cast<String, dynamic>()),
      },
      live: MatchLiveDto.fromJson((json['live'] as Map? ?? const {}).cast<String, dynamic>()),
      arena: (json['arena'] is Map) ? MatchArenaDto.fromJson((json['arena'] as Map).cast<String, dynamic>()) : null,
    );
  }
}

class MatchRulesDto {
  final OpponentRevealRulesDto opponentReveal;

  const MatchRulesDto({required this.opponentReveal});

  Map<String, dynamic> toJson() => {
        'opponentReveal': opponentReveal.toJson(),
      };

  factory MatchRulesDto.fromJson(Map<String, dynamic> json) {
    return MatchRulesDto(
      opponentReveal: OpponentRevealRulesDto.fromJson((json['opponentReveal'] as Map? ?? const {}).cast<String, dynamic>()),
    );
  }
}

class OpponentRevealRulesDto {
  final int radarPingTtlMs;

  const OpponentRevealRulesDto({required this.radarPingTtlMs});

  Map<String, dynamic> toJson() => {
        'radarPingTtlMs': radarPingTtlMs,
      };

  factory OpponentRevealRulesDto.fromJson(Map<String, dynamic> json) {
    return OpponentRevealRulesDto(
      radarPingTtlMs: (json['radarPingTtlMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class MatchTimeDto {
  final int serverNowMs;
  final int? prepEndsAtMs;
  final int? endsAtMs;

  const MatchTimeDto({
    required this.serverNowMs,
    this.prepEndsAtMs,
    this.endsAtMs,
  });

  Map<String, dynamic> toJson() => {
        'serverNowMs': serverNowMs,
        if (prepEndsAtMs != null) 'prepEndsAtMs': prepEndsAtMs,
        if (endsAtMs != null) 'endsAtMs': endsAtMs,
      };

  factory MatchTimeDto.fromJson(Map<String, dynamic> json) {
    return MatchTimeDto(
      serverNowMs: (json['serverNowMs'] as num?)?.toInt() ?? 0,
      prepEndsAtMs: (json['prepEndsAtMs'] as num?)?.toInt(),
      endsAtMs: (json['endsAtMs'] as num?)?.toInt(),
    );
  }
}

class MatchTeamsDto {
  final TeamPlayersDto police;
  final TeamPlayersDto thief;

  const MatchTeamsDto({required this.police, required this.thief});

  Map<String, dynamic> toJson() => {
        'POLICE': police.toJson(),
        'THIEF': thief.toJson(),
      };

  factory MatchTeamsDto.fromJson(Map<String, dynamic> json) {
    return MatchTeamsDto(
      police: TeamPlayersDto.fromJson((json['POLICE'] as Map? ?? const {}).cast<String, dynamic>()),
      thief: TeamPlayersDto.fromJson((json['THIEF'] as Map? ?? const {}).cast<String, dynamic>()),
    );
  }
}

class TeamPlayersDto {
  final List<String> playerIds;

  const TeamPlayersDto({required this.playerIds});

  Map<String, dynamic> toJson() => {
        'playerIds': playerIds,
      };

  factory TeamPlayersDto.fromJson(Map<String, dynamic> json) {
    return TeamPlayersDto(
      playerIds: (json['playerIds'] as List? ?? const []).map((e) => e.toString()).toList(),
    );
  }
}

class MatchPlayerDto {
  final String team; // 'POLICE' | 'THIEF'
  final String displayName;
  final String status; // server-defined string
  final Map<String, dynamic>? cooldowns;

  const MatchPlayerDto({
    required this.team,
    required this.displayName,
    required this.status,
    this.cooldowns,
  });

  Map<String, dynamic> toJson() => {
        'team': team,
        'displayName': displayName,
        'status': status,
        if (cooldowns != null) 'cooldowns': cooldowns,
      };

  factory MatchPlayerDto.fromJson(Map<String, dynamic> json) {
    return MatchPlayerDto(
      team: (json['team'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      cooldowns: (json['cooldowns'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

class MatchLiveDto {
  final MatchScoreDto? score;
  final CaptureProgressDto? captureProgress;
  final RescueProgressDto? rescueProgress;

  const MatchLiveDto({
    required this.score,
    required this.captureProgress,
    required this.rescueProgress,
  });

  Map<String, dynamic> toJson() => {
        if (score != null) 'score': score!.toJson(),
        if (captureProgress != null) 'captureProgress': captureProgress!.toJson(),
        if (rescueProgress != null) 'rescueProgress': rescueProgress!.toJson(),
      };

  factory MatchLiveDto.fromJson(Map<String, dynamic> json) {
    return MatchLiveDto(
      score: (json['score'] is Map) ? MatchScoreDto.fromJson((json['score'] as Map).cast<String, dynamic>()) : null,
      captureProgress: (json['captureProgress'] is Map)
          ? CaptureProgressDto.fromJson((json['captureProgress'] as Map).cast<String, dynamic>())
          : null,
      rescueProgress: (json['rescueProgress'] is Map)
          ? RescueProgressDto.fromJson((json['rescueProgress'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}

class MatchScoreDto {
  final int thiefFree;
  final int thiefCaptured;

  const MatchScoreDto({
    required this.thiefFree,
    required this.thiefCaptured,
  });

  Map<String, dynamic> toJson() => {
        'thiefFree': thiefFree,
        'thiefCaptured': thiefCaptured,
      };

  factory MatchScoreDto.fromJson(Map<String, dynamic> json) {
    return MatchScoreDto(
      thiefFree: (json['thiefFree'] as num?)?.toInt() ?? 0,
      thiefCaptured: (json['thiefCaptured'] as num?)?.toInt() ?? 0,
    );
  }
}

class CaptureProgressDto {
  final String? targetId;
  final String? byPoliceId;
  final double? progress01;
  final bool? nearOk;
  final bool? speedOk;
  final bool? timeOk;
  final bool? allOk;
  final int? allOkSinceMs;
  final int? lastUpdateMs;

  const CaptureProgressDto({
    required this.targetId,
    required this.byPoliceId,
    required this.progress01,
    required this.nearOk,
    required this.speedOk,
    required this.timeOk,
    required this.allOk,
    required this.allOkSinceMs,
    required this.lastUpdateMs,
  });

  Map<String, dynamic> toJson() => {
        if (targetId != null) 'targetId': targetId,
        if (byPoliceId != null) 'byPoliceId': byPoliceId,
        if (progress01 != null) 'progress01': progress01,
        if (nearOk != null) 'nearOk': nearOk,
        if (speedOk != null) 'speedOk': speedOk,
        if (timeOk != null) 'timeOk': timeOk,
        if (allOk != null) 'allOk': allOk,
        if (allOkSinceMs != null) 'allOkSinceMs': allOkSinceMs,
        if (lastUpdateMs != null) 'lastUpdateMs': lastUpdateMs,
      };

  factory CaptureProgressDto.fromJson(Map<String, dynamic> json) {
    return CaptureProgressDto(
      targetId: json['targetId']?.toString(),
      byPoliceId: json['byPoliceId']?.toString(),
      progress01: (json['progress01'] as num?)?.toDouble(),
      nearOk: json['nearOk'] as bool?,
      speedOk: json['speedOk'] as bool?,
      timeOk: json['timeOk'] as bool?,
      allOk: json['allOk'] as bool?,
      allOkSinceMs: (json['allOkSinceMs'] as num?)?.toInt(),
      lastUpdateMs: (json['lastUpdateMs'] as num?)?.toInt(),
    );
  }
}

class RescueProgressDto {
  final String? byThiefId;
  final double? progress01;
  final int? sinceMs;

  const RescueProgressDto({
    required this.byThiefId,
    required this.progress01,
    required this.sinceMs,
  });

  Map<String, dynamic> toJson() => {
        if (byThiefId != null) 'byThiefId': byThiefId,
        if (progress01 != null) 'progress01': progress01,
        if (sinceMs != null) 'sinceMs': sinceMs,
      };

  factory RescueProgressDto.fromJson(Map<String, dynamic> json) {
    return RescueProgressDto(
      byThiefId: json['byThiefId']?.toString(),
      progress01: (json['progress01'] as num?)?.toDouble(),
      sinceMs: (json['sinceMs'] as num?)?.toInt(),
    );
  }
}

class MatchArenaDto {
  final List<ArenaPointDto>? polygon;
  final ArenaJailDto? jail;

  const MatchArenaDto({required this.polygon, required this.jail});

  Map<String, dynamic> toJson() => {
        if (polygon != null) 'polygon': polygon!.map((e) => e.toJson()).toList(),
        if (jail != null) 'jail': jail!.toJson(),
      };

  factory MatchArenaDto.fromJson(Map<String, dynamic> json) {
    final raw = (json['polygon'] as List?) ?? const [];
    final parsed = raw
        .whereType<Map>()
        .map((e) => ArenaPointDto.fromJson(e.cast<String, dynamic>()))
        .toList();
    return MatchArenaDto(
      polygon: parsed.isEmpty ? null : parsed,
      jail: (json['jail'] is Map) ? ArenaJailDto.fromJson((json['jail'] as Map).cast<String, dynamic>()) : null,
    );
  }
}

class ArenaPointDto {
  final double lat;
  final double lng;

  const ArenaPointDto({required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
      };

  factory ArenaPointDto.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (json['lng'] as num?)?.toDouble() ?? 0.0;
    return ArenaPointDto(
      lat: lat.clamp(-90.0, 90.0),
      lng: lng.clamp(-180.0, 180.0),
    );
  }
}

class ArenaJailDto {
  final ArenaPointDto? center;
  final double? radiusM;

  const ArenaJailDto({required this.center, required this.radiusM});

  Map<String, dynamic> toJson() => {
        if (center != null) 'center': center!.toJson(),
        if (radiusM != null) 'radiusM': radiusM,
      };

  factory ArenaJailDto.fromJson(Map<String, dynamic> json) {
    final center = (json['center'] is Map) ? ArenaPointDto.fromJson((json['center'] as Map).cast<String, dynamic>()) : null;
    final radius = (json['radiusM'] as num?)?.toDouble();
    final validRadius = (radius == null || radius <= 0) ? null : radius;
    if (center == null || validRadius == null) return const ArenaJailDto(center: null, radiusM: null);
    return ArenaJailDto(center: center, radiusM: validRadius);
  }
}
