import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/history/record_model.dart';

/// Records data source (offline dummy for now).
///
/// TODO: Replace with server-authoritative data:
/// - REST: fetch MatchResult list
/// - WS: consume MatchState(ENDED) snapshots and build summaries
final recordsProvider = Provider<List<RecordSummary>>((ref) {
  final now = DateTime.now();

  final items = <RecordSummary>[
    RecordSummary(
      id: 'r_001',
      mode: 'NORMAL',
      myTeam: 'POLICE',
      result: 'WIN',
      ratingDelta: 12,
      playedAt: now.subtract(const Duration(hours: 6)),
      durationSec: 9 * 60 + 42,
      capturesOrRescues: 4,
      distanceM: 3820,
    ),
    RecordSummary(
      id: 'r_002',
      mode: 'ITEM',
      myTeam: 'THIEF',
      result: 'LOSE',
      ratingDelta: -8,
      playedAt: now.subtract(const Duration(days: 1, hours: 3)),
      durationSec: 11 * 60 + 5,
      capturesOrRescues: 2,
      distanceM: 5120,
    ),
    RecordSummary(
      id: 'r_003',
      mode: 'ABILITY',
      myTeam: 'POLICE',
      result: 'WIN',
      ratingDelta: 18,
      playedAt: now.subtract(const Duration(days: 2, hours: 9)),
      durationSec: 8 * 60 + 19,
      capturesOrRescues: 5,
      distanceM: 2940,
    ),
    RecordSummary(
      id: 'r_004',
      mode: 'NORMAL',
      myTeam: 'THIEF',
      result: 'WIN',
      ratingDelta: 6,
      playedAt: now.subtract(const Duration(days: 4, hours: 2)),
      durationSec: 10 * 60 + 0,
      capturesOrRescues: 3,
      distanceM: 7460,
    ),
  ];

  items.sort((a, b) => b.playedAt.compareTo(a.playedAt));
  return items;
});

