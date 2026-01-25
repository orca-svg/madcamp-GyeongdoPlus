import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/haptics/haptics.dart';
import '../../providers/match_sync_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/telemetry_scheduler_provider.dart';
import 'builders/ws_builders.dart';
import 'dto/telemetry.dart';
import 'ws_client.dart';
import 'ws_envelope.dart';
import 'ws_types.dart';

final wsServerHelloEpochProvider = NotifierProvider<WsServerHelloEpochController, int>(WsServerHelloEpochController.new);

class WsServerHelloEpochController extends Notifier<int> {
  @override
  int build() => 0;

  void set(int epoch) => state = epoch;
  void reset() => state = 0;
}

final wsClientProvider = Provider<WsClient>((ref) {
  final client = WsClient();
  ref.onDispose(() => client.dispose());
  return client;
});

final wsRouterProvider = Provider<WsRouter>((ref) {
  final router = WsRouter(ref);
  ref.onDispose(router.dispose);
  return router;
});

class WsRouter {
  final Ref _ref;
  late final StreamSubscription<WsEnvelope<Object?>> _sub;
  late final StreamSubscription<WsConnectionState> _connSub;

  WsRouter(this._ref) {
    final client = _ref.read(wsClientProvider);
    Future.microtask(() => _ref.read(telemetrySchedulerProvider.notifier).startWithClient(client));

    _sub = client.envelopes.listen(_onEnvelope);
    _connSub = client.connection.listen((s) {
      if (s.status == WsConnStatus.connected) {
        // Scheduler stays running; we only flush when connected.
      }
    });
  }

  void _onEnvelope(WsEnvelope<Object?> env) {
    if (env.type == WsType.telemetryHint) {
      final payloadRaw = env.payload;
      if (payloadRaw is Map) {
        final hint = TelemetryHintPayload.fromJson(payloadRaw.cast<String, dynamic>());
        _ref.read(telemetrySchedulerProvider.notifier).applyHint(hint);
      }
    }

    if (env.type == WsType.serverHello) {
      _ref.read(wsConnectionProvider.notifier).onServerHello();
    }

    final prevSeq = _ref.read(matchSyncProvider).lastSeq;
    final gap = _ref.read(matchSyncProvider.notifier).applyEnvelope(env);
    if (gap && env.matchId != null) {
      final room = _ref.read(roomProvider);
      if (room.myId.isNotEmpty) {
        final req = buildRequestSync(matchId: env.matchId!, playerId: room.myId, lastSeq: prevSeq, reason: 'SEQ_GAP');
        _ref.read(wsClientProvider).sendEnvelope(req, (p) => p);
      }
      if (kDebugMode) {
        Haptics.pattern(HapticPattern.warning);
      }
    }
  }

  void dispose() {
    _sub.cancel();
    _connSub.cancel();
  }
}

final wsConnectionProvider = NotifierProvider<WsConnectionController, WsConnectionState>(WsConnectionController.new);

class WsConnectionController extends Notifier<WsConnectionState> {
  StreamSubscription? _sub;
  int _activeEpoch = 0;
  int _helloSentEpoch = 0;
  int _serverHelloEpoch = 0;
  int _joinSentEpoch = 0;
  _JoinParams? _desiredJoin;
  _JoinParams? _pendingJoin;

  @override
  WsConnectionState build() {
    final client = ref.watch(wsClientProvider);
    _sub = client.connection.listen((s) {
      state = s;
      if (s.status == WsConnStatus.connected) {
        _onConnectedEpoch(client, s.epoch);
      } else {
        _resetGateForNextSession();
      }
    });
    ref.onDispose(() => _sub?.cancel());
    return client.connectionState;
  }

  Future<void> connect({
    Uri? url,
    Map<String, String>? headers,
  }) async {
    final u = url ?? Uri(scheme: 'wss', host: 'api.gyeongdo.plus', path: '/v1/ws');
    await ref.read(wsClientProvider).connect(url: u, headers: headers);
  }

  Future<void> disconnect() async {
    await ref.read(wsClientProvider).disconnect();
  }

  void sendJoinMatch({required String matchId, required String playerId, String? roomCode}) {
    final p = _JoinParams(matchId: matchId, playerId: playerId, roomCode: roomCode);
    _desiredJoin = p;
    _pendingJoin = p;
    _flushPendingJoin();
  }

  void onServerHello() {
    if (state.status != WsConnStatus.connected) return;
    _serverHelloEpoch = state.epoch;
    ref.read(wsServerHelloEpochProvider.notifier).set(state.epoch);
    _flushPendingJoin();
  }

  void _flushPendingJoin() {
    final p = _pendingJoin;
    if (p == null) return;
    if (state.status != WsConnStatus.connected) return;
    final epoch = state.epoch;
    if (_serverHelloEpoch != epoch) return;
    if (_joinSentEpoch == epoch) return;

    final env = buildJoinMatch(matchId: p.matchId, playerId: p.playerId, roomCode: p.roomCode);
    ref.read(wsClientProvider).sendEnvelope(env, (payload) => payload);
    _joinSentEpoch = epoch;
    _pendingJoin = null;
  }

  void _onConnectedEpoch(WsClient client, int epoch) {
    if (_activeEpoch != epoch) {
      _activeEpoch = epoch;
      _serverHelloEpoch = 0;
      _joinSentEpoch = 0;
      ref.read(wsServerHelloEpochProvider.notifier).reset();
      _pendingJoin = _desiredJoin;
    }
    if (_helloSentEpoch != epoch) {
      _helloSentEpoch = epoch;
      final hello = buildClientHello(device: 'flutter', appVersion: 'dev');
      ref.read(wsClientProvider).sendEnvelope(hello, (p) => p);
    }
    _flushPendingJoin();
  }

  void _resetGateForNextSession() {
    _serverHelloEpoch = 0;
    ref.read(wsServerHelloEpochProvider.notifier).reset();
    _pendingJoin = _desiredJoin;
  }
}

class _JoinParams {
  final String matchId;
  final String playerId;
  final String? roomCode;

  const _JoinParams({required this.matchId, required this.playerId, required this.roomCode});
}
