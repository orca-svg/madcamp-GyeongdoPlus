import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/net/ws/ws_client.dart';
import 'package:frontend/net/ws/ws_client_provider.dart';
import 'package:frontend/net/ws/ws_envelope.dart';
import 'package:frontend/net/ws/ws_types.dart';

class FakeWsClient extends WsClient {
  final StreamController<WsEnvelope<Object?>> _envCtrl = StreamController.broadcast();
  final StreamController<WsConnectionState> _connCtrl = StreamController.broadcast();

  WsConnectionState _state = WsConnectionState.initial();
  final List<Map<String, dynamic>> sent = [];

  @override
  Stream<WsEnvelope<Object?>> get envelopes => _envCtrl.stream;

  @override
  Stream<WsConnectionState> get connection => _connCtrl.stream;

  @override
  WsConnectionState get connectionState => _state;

  @override
  bool get isConnected => _state.status == WsConnStatus.connected;

  void emitEnvelope(WsEnvelope<Object?> env) => _envCtrl.add(env);

  void emitConn(WsConnectionState s) {
    _state = s;
    _connCtrl.add(s);
  }

  @override
  Future<void> connect({required Uri url, Map<String, String>? headers}) async {}

  @override
  Future<void> disconnect() async {}

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

  test('Handshake: hello every epoch, join gated by server_hello once per epoch', () async {
    final fake = FakeWsClient();
    final container = ProviderContainer(
      overrides: [
        wsClientProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    container.read(wsRouterProvider);

    final conn = container.read(wsConnectionProvider.notifier);
    conn.sendJoinMatch(matchId: 'm_123', playerId: 'p1', roomCode: 'ABCD');

    fake.emitConn(const WsConnectionState(status: WsConnStatus.connected, reconnectAttempt: 0, lastError: null, epoch: 1));
    await Future<void>.delayed(Duration.zero);

    expect(fake.sent.where((e) => e['type'] == WsType.clientHello.wire).length, 1);
    expect(fake.sent.where((e) => e['type'] == WsType.joinMatch.wire).length, 0);

    fake.emitEnvelope(const WsEnvelope<Object?>(
      v: 1,
      type: WsType.serverHello,
      matchId: null,
      seq: null,
      ts: 1,
      payload: {},
    ));
    await Future<void>.delayed(Duration.zero);

    expect(fake.sent.where((e) => e['type'] == WsType.joinMatch.wire).length, 1);

    fake.emitEnvelope(const WsEnvelope<Object?>(
      v: 1,
      type: WsType.serverHello,
      matchId: null,
      seq: null,
      ts: 2,
      payload: {},
    ));
    await Future<void>.delayed(Duration.zero);

    expect(fake.sent.where((e) => e['type'] == WsType.joinMatch.wire).length, 1);

    fake.emitConn(const WsConnectionState(status: WsConnStatus.disconnected, reconnectAttempt: 0, lastError: null, epoch: 1));
    await Future<void>.delayed(Duration.zero);

    fake.emitConn(const WsConnectionState(status: WsConnStatus.connected, reconnectAttempt: 1, lastError: null, epoch: 2));
    await Future<void>.delayed(Duration.zero);

    expect(fake.sent.where((e) => e['type'] == WsType.clientHello.wire).length, 2);
    expect(fake.sent.where((e) => e['type'] == WsType.joinMatch.wire).length, 1);

    fake.emitEnvelope(const WsEnvelope<Object?>(
      v: 1,
      type: WsType.serverHello,
      matchId: null,
      seq: null,
      ts: 3,
      payload: {},
    ));
    await Future<void>.delayed(Duration.zero);

    expect(fake.sent.where((e) => e['type'] == WsType.joinMatch.wire).length, 2);
  });
}
