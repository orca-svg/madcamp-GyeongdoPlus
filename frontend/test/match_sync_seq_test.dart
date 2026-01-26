import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/net/ws/ws_envelope.dart';
import 'package:frontend/net/ws/ws_types.dart';
import 'package:frontend/providers/match_sync_provider.dart';

void main() {
  test('MatchSyncController detects seq gap', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(matchSyncProvider.notifier);

    final e1 = WsEnvelope<Object?>(
      v: 1,
      type: WsType.matchEvent,
      matchId: 'm1',
      seq: 1,
      ts: 1,
      payload: const {'event': 'NOOP'},
    );
    final e3 = WsEnvelope<Object?>(
      v: 1,
      type: WsType.matchEvent,
      matchId: 'm1',
      seq: 3,
      ts: 2,
      payload: const {'event': 'NOOP'},
    );

    expect(controller.applyEnvelope(e1), isFalse);
    expect(container.read(matchSyncProvider).lastSeq, 1);

    expect(controller.applyEnvelope(e3), isTrue);
    expect(container.read(matchSyncProvider).lastSeq, 3);
  });
}

