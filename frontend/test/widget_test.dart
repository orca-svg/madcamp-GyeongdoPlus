// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/app.dart';
import 'package:frontend/net/ws/ws_client.dart';
import 'package:frontend/net/ws/ws_client_provider.dart';
import 'package:frontend/net/ws/ws_envelope.dart';
import 'package:frontend/net/ws/ws_types.dart';

void main() {
  testWidgets('App boots to OFF_GAME home', (WidgetTester tester) async {
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

  Future<void> signInStub(WidgetTester tester) async {
    expect(find.text('카카오 로그인'), findsOneWidget);
    await tester.tap(find.text('카카오 로그인'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('방 만들기'), findsOneWidget);
  }

  testWidgets('Create room -> Lobby shows room code', (
    WidgetTester tester,
  ) async {
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

    await signInStub(tester);

    await tester.tap(find.text('방 만들기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('방 생성'));
    await tester.pumpAndSettle();

    expect(find.text('로비'), findsOneWidget);
    expect(find.byKey(const Key('roomCodeText')), findsOneWidget);

    final codeText =
        tester.widget<Text>(find.byKey(const Key('roomCodeText'))).data ?? '';
    expect(codeText, isNotEmpty);
    expect(codeText, 'OFFLINE');
  });

  testWidgets('Lobby: ready locks team change, start shows dialog', (
    WidgetTester tester,
  ) async {
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

    await signInStub(tester);

    await tester.tap(find.text('방 만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('방 생성'));
    await tester.pumpAndSettle();

    final readyBtnFinder = find.byKey(const Key('lobbyReadyButton'));
    final startBtnFinder = find.byKey(const Key('lobbyStartButton'));

    // Sanity: keys should be unique.
    expect(readyBtnFinder.evaluate().length, 1);
    expect(startBtnFinder.evaluate().length, 1);

    final readyBtn = readyBtnFinder;
    final startBtn = startBtnFinder;

    await tester.ensureVisible(readyBtnFinder);
    await tester.pumpAndSettle();
    await tester.tap(readyBtn);
    await tester.pumpAndSettle();

    expect(find.text('Ready 해제 후 팀 변경 가능'), findsOneWidget);

    await tester.ensureVisible(startBtnFinder);
    await tester.pumpAndSettle();
    await tester.tap(startBtn);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text('자세히'), findsOneWidget);
    await tester.tap(find.text('자세히'));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text('시작 불가'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('로비'), findsOneWidget);
  });
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
