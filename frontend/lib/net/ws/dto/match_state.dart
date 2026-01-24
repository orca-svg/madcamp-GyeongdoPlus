class MatchStateDto {
  final String matchId;
  final String state; // 'LOBBY' | 'PREP' | 'RUNNING' | 'ENDED'
  final String mode;
  final MatchRulesDto rules;
  final MatchTimeDto time;
  final MatchTeamsDto teams;
  final Map<String, MatchPlayerDto> players;
  final MatchLiveDto live;

  const MatchStateDto({
    required this.matchId,
    required this.state,
    required this.mode,
    required this.rules,
    required this.time,
    required this.teams,
    required this.players,
    required this.live,
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
      };

  factory MatchStateDto.fromJson(Map<String, dynamic> json) {
    final playersRaw = (json['players'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return MatchStateDto(
      matchId: (json['matchId'] ?? '').toString(),
      state: (json['state'] ?? 'LOBBY').toString(),
      mode: (json['mode'] ?? '').toString(),
      rules: MatchRulesDto.fromJson((json['rules'] as Map? ?? const {}).cast<String, dynamic>()),
      time: MatchTimeDto.fromJson((json['time'] as Map? ?? const {}).cast<String, dynamic>()),
      teams: MatchTeamsDto.fromJson((json['teams'] as Map? ?? const {}).cast<String, dynamic>()),
      players: {
        for (final e in playersRaw.entries)
          e.key: MatchPlayerDto.fromJson((e.value as Map? ?? const {}).cast<String, dynamic>()),
      },
      live: MatchLiveDto.fromJson((json['live'] as Map? ?? const {}).cast<String, dynamic>()),
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
  final List<String> police;
  final List<String> thief;

  const MatchTeamsDto({required this.police, required this.thief});

  Map<String, dynamic> toJson() => {
        'police': police,
        'thief': thief,
      };

  factory MatchTeamsDto.fromJson(Map<String, dynamic> json) {
    return MatchTeamsDto(
      police: (json['police'] as List? ?? const []).map((e) => e.toString()).toList(),
      thief: (json['thief'] as List? ?? const []).map((e) => e.toString()).toList(),
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
  final Map<String, dynamic>? score;
  final double? captureProgress01;
  final double? rescueProgress01;

  const MatchLiveDto({
    required this.score,
    this.captureProgress01,
    this.rescueProgress01,
  });

  Map<String, dynamic> toJson() => {
        if (score != null) 'score': score,
        if (captureProgress01 != null) 'captureProgress01': captureProgress01,
        if (rescueProgress01 != null) 'rescueProgress01': rescueProgress01,
      };

  factory MatchLiveDto.fromJson(Map<String, dynamic> json) {
    return MatchLiveDto(
      score: (json['score'] as Map?)?.cast<String, dynamic>(),
      captureProgress01: (json['captureProgress01'] as num?)?.toDouble(),
      rescueProgress01: (json['rescueProgress01'] as num?)?.toDouble(),
    );
  }
}

