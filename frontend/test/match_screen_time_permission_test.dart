import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/match/match_screen.dart';
import 'package:frontend/net/ws/dto/match_state.dart';
import 'package:frontend/net/ws/ws_envelope.dart';
import 'package:frontend/net/ws/ws_types.dart';
import 'package:frontend/providers/match_sync_provider.dart';
import 'package:frontend/providers/room_provider.dart';

void main() {
  testWidgets('MatchScreen: non-host cannot change time', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(roomProvider.notifier).joinRoom(myName: '나', code: 'ABCD');
    final room = container.read(roomProvider);
    expect(room.amIHost, isFalse);

    final matchId = 'm_${room.roomCode}';
    final state = MatchStateDto(
      matchId: matchId,
      state: 'RUNNING',
      mode: 'NORMAL',
      rules: const MatchRulesDto(opponentReveal: OpponentRevealRulesDto(radarPingTtlMs: 7000)),
      time: const MatchTimeDto(serverNowMs: 1, prepEndsAtMs: null, endsAtMs: 999999),
      teams: const MatchTeamsDto(
        police: TeamPlayersDto(playerIds: <String>[]),
        thief: TeamPlayersDto(playerIds: <String>[]),
      ),
      players: const <String, MatchPlayerDto>{},
      live: const MatchLiveDto(
        score: MatchScoreDto(thiefFree: 1, thiefCaptured: 0),
        captureProgress: null,
        rescueProgress: null,
      ),
      arena: null,
    );
    container.read(matchSyncProvider.notifier).setMatchState(
          WsEnvelope<MatchStateDto>(
            v: 1,
            type: WsType.matchState,
            matchId: matchId,
            seq: 1,
            ts: 1,
            payload: state,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MatchScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('matchTimeSlider')), findsOneWidget);
    expect(find.byKey(const Key('matchTimePlus')), findsOneWidget);
    expect(find.byKey(const Key('matchTimeMinus')), findsOneWidget);

    final plus = tester.widget<IconButton>(find.byKey(const Key('matchTimePlus')));
    final minus = tester.widget<IconButton>(find.byKey(const Key('matchTimeMinus')));
    expect(plus.onPressed, isNull);
    expect(minus.onPressed, isNull);
  });
}
