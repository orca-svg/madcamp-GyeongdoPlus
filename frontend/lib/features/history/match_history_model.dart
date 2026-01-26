class MatchHistoryItem {
  final String id;
  final String mode; // NORMAL | ITEM | ABILITY
  final String myTeam; // POLICE | THIEF
  final String result; // WIN | LOSE
  final int ratingDelta;
  final DateTime playedAt;
  final int durationSec;
  final int capturesOrRescues;
  final int distanceM;

  const MatchHistoryItem({
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
}
