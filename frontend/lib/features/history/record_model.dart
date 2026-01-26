class RecordSummary {
  /// Front-end friendly summary model.
  ///
  /// Designed to be easily replaced by server-authoritative models later:
  /// - `mode`, `myTeam`, `result` are wire strings (1:1) for easy mapping.
  /// - `playedAt` can be derived from `MatchState.time.serverNowMs/endsAtMs` etc.
  /// - `durationSec` can be derived from `endsAtMs - prepEndsAtMs` (or game start).
  final String id;

  /// "NORMAL" | "ITEM" | "ABILITY"
  final String mode;

  /// "POLICE" | "THIEF"
  final String myTeam;

  /// "WIN" | "LOSE"
  final String result;

  /// e.g. +12 / -8
  final int ratingDelta;

  final DateTime playedAt;

  /// Total play duration in seconds (mm:ss).
  final int durationSec;

  /// Police: captures, Thief: rescues.
  final int capturesOrRescues;

  /// Meters (will be formatted as km).
  final int distanceM;

  const RecordSummary({
    required this.id,
    required this.mode,
    required this.myTeam,
    required this.result,
    required this.ratingDelta,
    required this.playedAt,
    required this.durationSec,
    required this.capturesOrRescues,
    required this.distanceM,
  });

  bool get isPolice => myTeam.toUpperCase() == 'POLICE';
}

