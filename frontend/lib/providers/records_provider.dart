import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/history/record_model.dart';
import 'user_provider.dart';

/// Maps server-fetched match history (via UserProvider) into UI-ready RecordSummary list.
/// Server data is the source of truth; local fallback defaults are used only for
/// fields not yet returned by the API (ratingDelta, distanceM, mode).
final recordsProvider = Provider<List<RecordSummary>>((ref) {
  final userState = ref.watch(userProvider);
  final history = userState.matchHistory;

  if (history.isEmpty) return [];

  return history.map((record) {
    // NOTE: GameInfoDto does not yet return 'mode' from server.
    // Default to 'NORMAL' until API exposes per-match mode.
    const mode = 'NORMAL';

    return RecordSummary(
      id: record.matchId,
      mode: mode,
      myTeam: record.role,
      result: record.result,
      // NOTE: MatchRecordDto does not yet return ratingDelta from server.
      // Estimate from result until API provides actual MMR delta.
      ratingDelta: (record.result == 'WIN') ? 10 : (record.result == 'DRAW' ? 0 : -5),
      playedAt: record.gameInfo.playedAt,
      durationSec: record.gameInfo.playTime,
      // Map catch/rescue count from server stats
      capturesOrRescues: record.role == 'POLICE'
          ? record.myStat.catchCount
          : (record.myStat.rescueCount ?? 0),
      // NOTE: MyStatDto does not yet return distanceM from server.
      // Default to 0 until API provides per-match distance.
      distanceM: 0,
    );
  }).toList();
});
