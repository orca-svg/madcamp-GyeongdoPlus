import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/net/ws/ws_client.dart';
import 'package:frontend/net/ws/ws_client_provider.dart';
import 'package:frontend/net/ws/ws_envelope.dart';
import 'package:frontend/net/ws/ws_types.dart';
import 'package:frontend/net/ws/dto/match_state.dart';
import 'package:frontend/providers/match_sync_provider.dart';
import 'package:frontend/providers/ws_ui_status_provider.dart';

class _FakeWsConnController extends WsConnectionController {
  final WsConnectionState _value;
  _FakeWsConnController(this._value);

  @override
  WsConnectionState build() => _value;
}

class _FakeServerHelloEpochController extends WsServerHelloEpochController {
  final int _value;
  _FakeServerHelloEpochController(this._value);

  @override
  int build() => _value;
}

class _FakeMatchSyncController extends MatchSyncController {
  final MatchSyncState _value;
  _FakeMatchSyncController(this._value);

  @override
  MatchSyncState build() => _value;
}

ProviderContainer _container({
  required WsConnectionState conn,
  required int serverHelloEpoch,
  required bool hasSnapshot,
}) {
  return ProviderContainer(
    overrides: [
      wsConnectionProvider.overrideWith(() => _FakeWsConnController(conn)),
      wsServerHelloEpochProvider.overrideWith(() => _FakeServerHelloEpochController(serverHelloEpoch)),
      matchSyncProvider.overrideWith(
        () => _FakeMatchSyncController(
          MatchSyncState(
            lastMatchState: hasSnapshot ? _stubMatchStateEnvelope : null,
            lastRadarPing: null,
            lastJsonPreview: null,
            lastSeq: null,
            currentMatchId: null,
          ),
        ),
      ),
    ],
  );
}

void main() {
  test('wsUiStatusProvider derives status from connection/serverHello/snapshot', () {
    final c1 = _container(
      conn: const WsConnectionState(status: WsConnStatus.disconnected, reconnectAttempt: 0, lastError: null, epoch: 0),
      serverHelloEpoch: 0,
      hasSnapshot: false,
    );
    addTearDown(c1.dispose);
    expect(c1.read(wsUiStatusProvider).status, WsUiStatus.disconnected);

    final c2 = _container(
      conn: const WsConnectionState(status: WsConnStatus.connected, reconnectAttempt: 0, lastError: null, epoch: 2),
      serverHelloEpoch: 0,
      hasSnapshot: false,
    );
    addTearDown(c2.dispose);
    expect(c2.read(wsUiStatusProvider).status, WsUiStatus.awaitingServerHello);

    final c3 = _container(
      conn: const WsConnectionState(status: WsConnStatus.connected, reconnectAttempt: 0, lastError: null, epoch: 2),
      serverHelloEpoch: 2,
      hasSnapshot: false,
    );
    addTearDown(c3.dispose);
    expect(c3.read(wsUiStatusProvider).status, WsUiStatus.awaitingSnapshot);

    final c4 = _container(
      conn: const WsConnectionState(status: WsConnStatus.connected, reconnectAttempt: 0, lastError: null, epoch: 2),
      serverHelloEpoch: 2,
      hasSnapshot: true,
    );
    addTearDown(c4.dispose);
    expect(c4.read(wsUiStatusProvider).status, WsUiStatus.synced);
  });
}

const _stubMatchStateEnvelope = WsEnvelope<MatchStateDto>(
  v: 1,
  type: WsType.matchState,
  matchId: 'm_1',
  seq: 1,
  ts: 1,
  payload: MatchStateDto(
    matchId: 'm_1',
    state: 'RUNNING',
    mode: 'NORMAL',
    rules: MatchRulesDto(opponentReveal: OpponentRevealRulesDto(radarPingTtlMs: 7000)),
    time: MatchTimeDto(serverNowMs: 1, prepEndsAtMs: null, endsAtMs: null),
    teams: MatchTeamsDto(
      police: TeamPlayersDto(playerIds: <String>[]),
      thief: TeamPlayersDto(playerIds: <String>[]),
    ),
    players: <String, MatchPlayerDto>{},
    live: MatchLiveDto(score: null, captureProgress: null, rescueProgress: null),
  ),
);
