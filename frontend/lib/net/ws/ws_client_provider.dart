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
  WsConnStatus _lastStatus = WsConnStatus.disconnected;

  WsRouter(this._ref) {
    final client = _ref.read(wsClientProvider);

    _sub = client.envelopes.listen(_onEnvelope);
    _connSub = client.connection.listen((s) {
      final wasConnected = _lastStatus == WsConnStatus.connected;
      _lastStatus = s.status;

      if (s.status == WsConnStatus.connected) {
        _ref.read(telemetrySchedulerProvider.notifier).startWithClient(client);
        if (!wasConnected) {
          final matchId = _ref.read(matchSyncProvider).lastMatchState?.payload.matchId;
          final room = _ref.read(roomProvider);
          if (matchId != null && matchId.isNotEmpty && room.myId.isNotEmpty) {
            final join = buildJoinMatch(matchId: matchId, playerId: room.myId, roomCode: room.roomCode);
            _ref.read(wsClientProvider).sendEnvelope(join, (p) => p);
          }
        }
      }
      if (s.status == WsConnStatus.disconnected) {
        _ref.read(telemetrySchedulerProvider.notifier).stop();
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

    final gap = _ref.read(matchSyncProvider.notifier).applyEnvelope(env);
    if (gap && env.matchId != null) {
      final lastSeq = _ref.read(matchSyncProvider).lastSeq;
      final req = buildRequestSync(matchId: env.matchId!, lastSeq: lastSeq, reason: 'SEQ_GAP');
      _ref.read(wsClientProvider).sendEnvelope(req, (p) => p);
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

  @override
  WsConnectionState build() {
    final client = ref.watch(wsClientProvider);
    _sub = client.connection.listen((s) => state = s);
    ref.onDispose(() => _sub?.cancel());
    return client.connectionState;
  }

  Future<void> connect({
    Uri? url,
    Map<String, String>? headers,
  }) async {
    final u = url ?? Uri(scheme: 'wss', host: 'api.gyeongdo.plus', path: '/v1/ws');
    await ref.read(wsClientProvider).connect(url: u, headers: headers);
    final hello = buildClientHello(device: 'flutter', appVersion: 'dev');
    ref.read(wsClientProvider).sendEnvelope(hello, (p) => p);
  }

  Future<void> disconnect() async {
    await ref.read(wsClientProvider).disconnect();
  }

  void sendJoinMatch({required String matchId, required String playerId, String? roomCode}) {
    final env = buildJoinMatch(matchId: matchId, playerId: playerId, roomCode: roomCode);
    ref.read(wsClientProvider).sendEnvelope(env, (p) => p);
  }
}
