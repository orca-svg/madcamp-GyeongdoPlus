import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/net/ws/ws_client.dart';
import 'package:frontend/net/ws/ws_client_provider.dart';
import 'package:frontend/net/ws/ws_envelope.dart';
import 'package:frontend/net/ws/ws_types.dart';
import 'package:frontend/providers/room_provider.dart';

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

  void emit(WsEnvelope<Object?> env) => _envCtrl.add(env);

  void setConnection(WsConnectionState s) {
    _state = s;
    _connCtrl.add(s);
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

  test('WsRouter sends REQUEST_SYNC(action) on seq gap', () async {
    final fake = FakeWsClient();
    final container = ProviderContainer(
      overrides: [
        wsClientProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    container.read(wsRouterProvider);
    await container.read(roomProvider.notifier).createRoom(myName: 'me');

    fake.emit(
      const WsEnvelope<Object?>(
        v: 1,
        type: WsType.matchEvent,
        matchId: 'm_123',
        seq: 1,
        ts: 1,
        payload: {'event': 'NOOP'},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    fake.emit(
      const WsEnvelope<Object?>(
        v: 1,
        type: WsType.matchEvent,
        matchId: 'm_123',
        seq: 3,
        ts: 2,
        payload: {'event': 'NOOP'},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final sentActions = fake.sent.where((e) => e['type'] == WsType.action.wire).toList();
    expect(sentActions.length, 1);
    final payload = (sentActions.single['payload'] as Map).cast<String, dynamic>();
    expect(payload['actionType'], 'REQUEST_SYNC');
    expect((payload['meta'] as Map)['lastSeq'], 1);
  });
}
