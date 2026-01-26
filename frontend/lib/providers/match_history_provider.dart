import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/history/match_history_model.dart';

final matchHistoryProvider = Provider<List<MatchHistoryItem>>((ref) {
  final now = DateTime.now();
  return [
    MatchHistoryItem(
      id: 'm1',
      mode: 'NORMAL',
      myTeam: 'POLICE',
      result: 'WIN',
      ratingDelta: 12,
      playedAt: now.subtract(const Duration(minutes: 12)),
      durationSec: 520,
      capturesOrRescues: 3,
      distanceM: 1840,
    ),
    MatchHistoryItem(
      id: 'm2',
      mode: 'ITEM',
      myTeam: 'THIEF',
      result: 'LOSE',
      ratingDelta: -8,
      playedAt: now.subtract(const Duration(hours: 2)),
      durationSec: 740,
      capturesOrRescues: 1,
      distanceM: 2620,
    ),
    MatchHistoryItem(
      id: 'm3',
      mode: 'ABILITY',
      myTeam: 'POLICE',
      result: 'WIN',
      ratingDelta: 18,
      playedAt: now.subtract(const Duration(days: 1, hours: 3)),
      durationSec: 610,
      capturesOrRescues: 4,
      distanceM: 2100,
    ),
    MatchHistoryItem(
      id: 'm4',
      mode: 'NORMAL',
      myTeam: 'THIEF',
      result: 'WIN',
      ratingDelta: 10,
      playedAt: now.subtract(const Duration(days: 2)),
      durationSec: 480,
      capturesOrRescues: 2,
      distanceM: 1320,
    ),
    MatchHistoryItem(
      id: 'm5',
      mode: 'ITEM',
      myTeam: 'POLICE',
      result: 'LOSE',
      ratingDelta: -11,
      playedAt: now.subtract(const Duration(days: 3, hours: 5)),
      durationSec: 830,
      capturesOrRescues: 1,
      distanceM: 2950,
    ),
    MatchHistoryItem(
      id: 'm6',
      mode: 'ABILITY',
      myTeam: 'THIEF',
      result: 'LOSE',
      ratingDelta: -6,
      playedAt: now.subtract(const Duration(days: 5)),
      durationSec: 560,
      capturesOrRescues: 3,
      distanceM: 1780,
    ),
  ];
});
