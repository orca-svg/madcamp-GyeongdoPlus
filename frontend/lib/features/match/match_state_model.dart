class MatchTimeSnapshot {
  final int serverNowMs;
  final int? prepEndsAtMs;
  final int? endsAtMs;

  const MatchTimeSnapshot({
    required this.serverNowMs,
    required this.prepEndsAtMs,
    required this.endsAtMs,
  });

  MatchTimeSnapshot copyWith({int? serverNowMs, int? prepEndsAtMs, int? endsAtMs}) {
    return MatchTimeSnapshot(
      serverNowMs: serverNowMs ?? this.serverNowMs,
      prepEndsAtMs: prepEndsAtMs ?? this.prepEndsAtMs,
      endsAtMs: endsAtMs ?? this.endsAtMs,
    );
  }
}

class MatchScoreSnapshot {
  final int thiefFree;
  final int thiefCaptured;

  const MatchScoreSnapshot({required this.thiefFree, required this.thiefCaptured});

  MatchScoreSnapshot copyWith({int? thiefFree, int? thiefCaptured}) {
    return MatchScoreSnapshot(
      thiefFree: thiefFree ?? this.thiefFree,
      thiefCaptured: thiefCaptured ?? this.thiefCaptured,
    );
  }
}

class CaptureProgressSnapshot {
  final double progress01;
  final bool nearOk;
  final bool speedOk;
  final bool timeOk;
  final bool allOk;
  final String? targetId;

  const CaptureProgressSnapshot({
    required this.progress01,
    required this.nearOk,
    required this.speedOk,
    required this.timeOk,
    required this.allOk,
    required this.targetId,
  });

  CaptureProgressSnapshot copyWith({
    double? progress01,
    bool? nearOk,
    bool? speedOk,
    bool? timeOk,
    bool? allOk,
    String? targetId,
  }) {
    return CaptureProgressSnapshot(
      progress01: progress01 ?? this.progress01,
      nearOk: nearOk ?? this.nearOk,
      speedOk: speedOk ?? this.speedOk,
      timeOk: timeOk ?? this.timeOk,
      allOk: allOk ?? this.allOk,
      targetId: targetId ?? this.targetId,
    );
  }
}

class RescueProgressSnapshot {
  final double progress01;
  final String? byThiefId;

  const RescueProgressSnapshot({required this.progress01, required this.byThiefId});

  RescueProgressSnapshot copyWith({double? progress01, String? byThiefId}) {
    return RescueProgressSnapshot(
      progress01: progress01 ?? this.progress01,
      byThiefId: byThiefId ?? this.byThiefId,
    );
  }
}

class MatchLiveSnapshot {
  final MatchScoreSnapshot score;
  final CaptureProgressSnapshot? captureProgress;
  final RescueProgressSnapshot? rescueProgress;

  const MatchLiveSnapshot({
    required this.score,
    required this.captureProgress,
    required this.rescueProgress,
  });

  MatchLiveSnapshot copyWith({
    MatchScoreSnapshot? score,
    CaptureProgressSnapshot? captureProgress,
    RescueProgressSnapshot? rescueProgress,
  }) {
    return MatchLiveSnapshot(
      score: score ?? this.score,
      captureProgress: captureProgress ?? this.captureProgress,
      rescueProgress: rescueProgress ?? this.rescueProgress,
    );
  }
}

class MatchStateSnapshot {
  /// "LOBBY" | "PREP" | "RUNNING" | "ENDED"
  final String state;

  /// "NORMAL" | "ITEM" | "ABILITY"
  final String mode;

  final MatchTimeSnapshot time;
  final MatchLiveSnapshot live;

  /// Optional one-off notice for UI (e.g. capture confirmed).
  final int noticeSeq;
  final String? noticeMessage;

  const MatchStateSnapshot({
    required this.state,
    required this.mode,
    required this.time,
    required this.live,
    required this.noticeSeq,
    required this.noticeMessage,
  });

  MatchStateSnapshot copyWith({
    String? state,
    String? mode,
    MatchTimeSnapshot? time,
    MatchLiveSnapshot? live,
    int? noticeSeq,
    String? noticeMessage,
  }) {
    return MatchStateSnapshot(
      state: state ?? this.state,
      mode: mode ?? this.mode,
      time: time ?? this.time,
      live: live ?? this.live,
      noticeSeq: noticeSeq ?? this.noticeSeq,
      noticeMessage: noticeMessage ?? this.noticeMessage,
    );
  }
}

