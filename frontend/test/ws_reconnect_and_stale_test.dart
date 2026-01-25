import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/net/ws/ws_client.dart';
import 'package:frontend/net/ws/ws_client_provider.dart';
import 'package:frontend/net/ws/ws_envelope.dart';
import 'package:frontend/net/ws/ws_types.dart';
import 'package:frontend/providers/match_sync_provider.dart';
import 'package:frontend/providers/room_provider.dart';
import 'package:frontend/providers/ws_notice_provider.dart';

class FakeWsClient extends WsClient {
  final StreamController<WsEnvelope<Object?>> _envCtrl = StreamController.broadcast();
  final StreamController<WsConnectionState> _connCtrl = StreamController.broadcast();

  WsConnectionState _state = WsConnectionState.initial();
  int connectCalls = 0;
  int disconnectCalls = 0;
  final List<Map<String, dynamic>> sent = [];

  @override
  Stream<WsEnvelope<Object?>> get envelopes => _envCtrl.stream;

  @override
  Stream<WsConnectionState> get connection => _connCtrl.stream;

  @override
  WsConnectionState get connectionState => _state;

  @override
  bool get isConnected => _state.status == WsConnStatus.connected;

  void emitConn(WsConnectionState s) {
    _state = s;
    _connCtrl.add(s);
  }

  void emitEnvelope(WsEnvelope<Object?> e) => _envCtrl.add(e);

  @override
  Future<void> connect({required Uri url, Map<String, String>? headers}) async {
    connectCalls += 1;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
  }

  @override
  void sendEnvelope<T>(WsEnvelope<T> env, Map<String, dynamic> Function(T) payloadToJson) {
    sent.add(env.toJson(payloadToJson));
  }

  @override
  Future<void> dispose() async {
    await _envCtrl.close();
    await _connCtrl.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('userReconnect is throttled and ignored when not disconnected', (tester) async {
    final fake = FakeWsClient();
    final container = ProviderContainer(
      overrides: [
        wsClientProvider.overrideWithValue(fake),
      ],
    );

    final conn = container.read(wsConnectionProvider.notifier);

    await conn.userReconnect();
    await conn.userReconnect();
    expect(fake.connectCalls, 1);

    await tester.pump(const Duration(milliseconds: 800));
    await conn.userReconnect();
    expect(fake.connectCalls, 1);

    await tester.pump(const Duration(milliseconds: 600));
    await conn.userReconnect();
    expect(fake.connectCalls, 2);

    fake.emitConn(const WsConnectionState(status: WsConnStatus.connecting, reconnectAttempt: 0, lastError: null, epoch: 1));
    await conn.userReconnect();
    expect(fake.connectCalls, 2);

    await tester.pump(const Duration(seconds: 3));
    container.dispose();
  });

  testWidgets('stale awaitingSnapshot triggers REQUEST_SYNC then reconnect', (tester) async {
    final fake = FakeWsClient();
    final container = ProviderContainer(
      overrides: [
        wsClientProvider.overrideWithValue(fake),
      ],
    );

    container.read(roomProvider.notifier).createRoom(myName: 'me');
    container.read(matchSyncProvider.notifier).setCurrentMatchId('m_123');

    container.read(wsRouterProvider);
    container.read(wsStaleRecoveryProvider);

    fake.emitConn(const WsConnectionState(status: WsConnStatus.connected, reconnectAttempt: 0, lastError: null, epoch: 1));
    fake.emitEnvelope(const WsEnvelope<Object?>(
      v: 1,
      type: WsType.serverHello,
      matchId: null,
      seq: null,
      ts: 1,
      payload: {},
    ));

    await tester.pump(const Duration(seconds: 4));

    final actions = fake.sent.where((e) => e['type'] == WsType.action.wire).toList();
    expect(actions.length, 1);
    final payload = (actions.single['payload'] as Map).cast<String, dynamic>();
    expect(payload['actionType'], 'REQUEST_SYNC');
    expect((payload['meta'] as Map)['reason'], 'STALE_SNAPSHOT');

    await tester.pump(const Duration(seconds: 3));
    expect(fake.disconnectCalls, 1);
    expect(fake.connectCalls >= 1, isTrue);

    container.dispose();
  });

  testWidgets('ws notices: short flap suppressed, long disconnect emits once then reconnected once', (tester) async {
    final fake = FakeWsClient();
    final container = ProviderContainer(
      overrides: [
        wsClientProvider.overrideWithValue(fake),
      ],
    );

    container.read(wsNoticeProvider);

    fake.emitConn(const WsConnectionState(status: WsConnStatus.connected, reconnectAttempt: 0, lastError: null, epoch: 1));
    fake.emitConn(const WsConnectionState(status: WsConnStatus.disconnected, reconnectAttempt: 0, lastError: null, epoch: 1));
    await tester.pump(const Duration(milliseconds: 400));
    fake.emitConn(const WsConnectionState(status: WsConnStatus.connected, reconnectAttempt: 0, lastError: null, epoch: 2));

    expect(container.read(wsNoticeProvider), isNull);

    fake.emitConn(const WsConnectionState(status: WsConnStatus.disconnected, reconnectAttempt: 0, lastError: null, epoch: 2));
    await tester.pump(const Duration(milliseconds: 2100));
    expect(container.read(wsNoticeProvider)?.type, WsNoticeType.disconnectedLong);
    container.read(wsNoticeProvider.notifier).consume();

    fake.emitConn(const WsConnectionState(status: WsConnStatus.connected, reconnectAttempt: 0, lastError: null, epoch: 3));
    await tester.pump();
    expect(container.read(wsNoticeProvider)?.type, WsNoticeType.reconnected);

    container.dispose();
  });
}
