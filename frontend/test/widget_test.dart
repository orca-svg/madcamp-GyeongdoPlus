import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/app.dart';
import 'package:frontend/core/env.dart';
import 'package:frontend/core/services/audio_service.dart';
import 'package:frontend/core/widgets/gradient_button.dart';
import 'package:frontend/net/ws/ws_client.dart';
import 'package:frontend/net/ws/ws_client_provider.dart';
import 'package:frontend/net/ws/ws_envelope.dart';
import 'package:frontend/net/ws/ws_types.dart';
import 'package:frontend/providers/room_provider.dart';
import 'package:frontend/ui/lobby/lobby_screen.dart';

void main() {
  setUp(() {
    Env.debugForceDisableMaps(true);
  });

  tearDown(() {
    Env.debugForceDisableMaps(false);
  });

  Future<ProviderContainer> lobbyContainer() async {
    SharedPreferences.setMockInitialValues({});
    final ws = _NoopWsClient();
    final container = ProviderContainer(
      overrides: [
        wsClientProvider.overrideWithValue(ws),
        audioServiceProvider.overrideWithValue(_SilentAudioService()),
      ],
    );
    addTearDown(ws.dispose);
    return container;
  }

  testWidgets('App boots to login when signed out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final ws = _NoopWsClient();
    addTearDown(ws.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [wsClientProvider.overrideWithValue(ws)],
        child: const GyeongdoPlusApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('카카오 로그인'), findsOneWidget);
  });

  testWidgets('Offline lobby shows room code', (WidgetTester tester) async {
    final container = await lobbyContainer();
    addTearDown(container.dispose);

    container.read(roomProvider.notifier).enterLobbyOffline(myName: 'tester');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LobbyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('roomCodeText')), findsOneWidget);

    final codeText =
        tester.widget<Text>(find.byKey(const Key('roomCodeText'))).data ?? '';
    expect(codeText, 'OFFLINE');
  });

  testWidgets('Lobby: ready locks team change and start stays blocked', (
    WidgetTester tester,
  ) async {
    final container = await lobbyContainer();
    addTearDown(container.dispose);

    container.read(roomProvider.notifier).enterLobbyOffline(myName: 'tester');
    container.read(roomProvider.notifier).addFakeMember();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LobbyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final startBtnFinder = find.byKey(const Key('lobbyStartButton'));

    expect(startBtnFinder.evaluate().length, 1);
    expect(find.text('WAIT'), findsNWidgets(2));

    await tester.tap(find.text('WAIT').first);
    await tester.pumpAndSettle();

    expect(find.text('READY'), findsOneWidget);

    final startButton = tester.widget<GradientButton>(startBtnFinder);
    expect(startButton.onPressed, isNull);
  });
}

class _SilentAudioService extends AudioService {
  @override
  Future<void> playBgm(AudioType type) async {}

  @override
  Future<void> stopBgm() async {}

  @override
  Future<void> playSfx(AudioType type) async {}
}

class _NoopWsClient extends WsClient {
  final StreamController<WsEnvelope<Object?>> _envCtrl =
      StreamController.broadcast();
  final StreamController<WsConnectionState> _connCtrl =
      StreamController.broadcast();

  WsConnectionState _state = WsConnectionState.initial();
  int _epoch = 0;
  String? _lastJoinMatchId;

  @override
  Stream<WsEnvelope<Object?>> get envelopes => _envCtrl.stream;

  @override
  Stream<WsConnectionState> get connection => _connCtrl.stream;

  @override
  WsConnectionState get connectionState => _state;

  @override
  bool get isConnected => false;

  @override
  Future<void> connect({required Uri url, Map<String, String>? headers}) async {
    _epoch += 1;
    _state = _state.copyWith(status: WsConnStatus.connected, epoch: _epoch);
    _connCtrl.add(_state);
    _envCtrl.add(
      WsEnvelope<Object?>(
        v: 1,
        type: WsType.serverHello,
        matchId: null,
        seq: null,
        ts: DateTime.now().millisecondsSinceEpoch,
        payload: const {},
      ),
    );
  }

  @override
  Future<void> disconnect() async {
    _state = WsConnectionState.initial();
    _connCtrl.add(_state);
  }

  @override
  void sendEnvelope<T>(
    WsEnvelope<T> env,
    Map<String, dynamic> Function(T) payloadToJson,
  ) {
    if (env.type == WsType.joinMatch) {
      final p = env.payload;
      if (p is Map) {
        _lastJoinMatchId = (p['matchId'] ?? '').toString();
      }
      final matchId = _lastJoinMatchId ?? 'm_test';
      _envCtrl.add(
        WsEnvelope<Object?>(
          v: 1,
          type: WsType.matchState,
          matchId: matchId,
          seq: 1,
          ts: DateTime.now().millisecondsSinceEpoch,
          payload: {
            'matchId': matchId,
            'state': 'RUNNING',
            'mode': 'NORMAL',
            'rules': {
              'opponentReveal': {'radarPingTtlMs': 7000},
            },
            'time': {
              'serverNowMs': DateTime.now().millisecondsSinceEpoch,
              'prepEndsAtMs': null,
              'endsAtMs': DateTime.now().millisecondsSinceEpoch + 120000,
            },
            'teams': {
              'POLICE': {'playerIds': const <String>[]},
              'THIEF': {'playerIds': const <String>[]},
            },
            'players': const <String, dynamic>{},
            'live': {
              'score': {'thiefFree': 1, 'thiefCaptured': 0},
              'captureProgress': null,
              'rescueProgress': null,
            },
          },
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    await _envCtrl.close();
    await _connCtrl.close();
  }
}
