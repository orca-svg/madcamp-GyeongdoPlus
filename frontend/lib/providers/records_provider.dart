import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/history/record_model.dart';
import 'user_provider.dart';

/// Records data source (offline dummy for now).
///
/// TODO: Replace with server-authoritative data:
/// - REST: fetch MatchResult list
/// - WS: consume MatchState(ENDED) snapshots and build summaries
final recordsProvider = Provider<List<RecordSummary>>((ref) {
  final userState = ref.watch(userProvider);
  final history = userState.matchHistory;

  if (history.isEmpty) return [];

  return history.map((record) {
    // Map DTO to UI Model

    // Attempt to infer mode or default to NORMAL
    // If specific mode info becomes available in DTO, update here.
    String mode = 'NORMAL';

    return RecordSummary(
      id: record.matchId,
      mode: mode,
      myTeam: record.role,
      result: record.result,
      // API currently doesn't return rating delta per match, defaulting to 0 or logic
      ratingDelta: (record.result == 'WIN') ? 10 : -5,
      playedAt: record.gameInfo.playedAt,
      durationSec: record.gameInfo.playTime,
      // Map catch/rescue count
      capturesOrRescues: record.role == 'POLICE'
          ? record.myStat.catchCount
          : (record.myStat.rescueCount ?? 0),
      // Distance not in MatchRecordDto summary yet, default 0
      distanceM: 0,
    );
  }).toList();
});
