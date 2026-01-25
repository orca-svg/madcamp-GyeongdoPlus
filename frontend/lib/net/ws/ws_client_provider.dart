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
  bool _serverHelloReceived = false;
  _JoinParams? _desiredJoin;
  _JoinParams? _pendingJoin;

  @override
  WsConnectionState build() {
    final client = ref.watch(wsClientProvider);
    _sub = client.connection.listen((s) {
      state = s;
      if (s.status != WsConnStatus.connected) {
        _serverHelloReceived = false;
      }
      if (s.status == WsConnStatus.connected) {
        _pendingJoin = _desiredJoin;
        _flushPendingJoin();
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
    _serverHelloReceived = false;
    await ref.read(wsClientProvider).connect(url: u, headers: headers);
    final hello = buildClientHello(device: 'flutter', appVersion: 'dev');
    ref.read(wsClientProvider).sendEnvelope(hello, (p) => p);
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
    _serverHelloReceived = true;
    _flushPendingJoin();
  }

  void _flushPendingJoin() {
    final p = _pendingJoin;
    if (p == null) return;
    if (!_serverHelloReceived) return;
    if (state.status != WsConnStatus.connected) return;

    final env = buildJoinMatch(matchId: p.matchId, playerId: p.playerId, roomCode: p.roomCode);
    ref.read(wsClientProvider).sendEnvelope(env, (payload) => payload);
    _pendingJoin = null;
  }
}

class _JoinParams {
  final String matchId;
  final String playerId;
  final String? roomCode;

  const _JoinParams({required this.matchId, required this.playerId, required this.roomCode});
}
