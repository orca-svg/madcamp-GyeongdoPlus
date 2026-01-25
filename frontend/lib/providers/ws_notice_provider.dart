import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../net/ws/builders/ws_builders.dart';
import '../net/ws/ws_client.dart';
import '../net/ws/ws_client_provider.dart';
import 'match_sync_provider.dart';
import 'room_provider.dart';

enum WsNoticeType { disconnectedLong, reconnected }

class WsNotice {
  final WsNoticeType type;
  final String message;
  final int tsMs;

  const WsNotice({
    required this.type,
    required this.message,
    required this.tsMs,
  });
}

final wsNoticeProvider = NotifierProvider<WsNoticeController, WsNotice?>(WsNoticeController.new);

class WsNoticeController extends Notifier<WsNotice?> {
  Timer? _disconnectTimer;
  Timer? _flapTimer;
  Timer? _cooldownTimer;
  bool _flapWindowPassed = true;
  bool _disconnectShown = false;
  WsNoticeType? _lastType;
  bool _cooldownActive = false;

  @override
  WsNotice? build() {
    ref.onDispose(() {
      _disconnectTimer?.cancel();
      _flapTimer?.cancel();
      _cooldownTimer?.cancel();
    });
    ref.listen<WsConnectionState>(wsConnectionProvider, (prev, next) {
      _onConnChanged(prev, next);
    });
    return null;
  }

  WsNotice? consume() {
    final v = state;
    state = null;
    return v;
  }

  void _onConnChanged(WsConnectionState? prev, WsConnectionState next) {
    if (next.status == WsConnStatus.disconnected) {
      _flapWindowPassed = false;
      _flapTimer?.cancel();
      _flapTimer = Timer(const Duration(milliseconds: 500), () {
        _flapWindowPassed = true;
      });
      _disconnectTimer?.cancel();
      _disconnectTimer = Timer(const Duration(seconds: 2), () {
        if (!ref.mounted) return;
        final cur = ref.read(wsConnectionProvider);
        final stillDisconnected = cur.status == WsConnStatus.disconnected;
        if (stillDisconnected) {
          _emitOnce(
            WsNoticeType.disconnectedLong,
            '연결이 끊어졌어요. 재연결 중…',
          );
          _disconnectShown = true;
        }
      });
      return;
    }

    if (next.status == WsConnStatus.connected) {
      _disconnectTimer?.cancel();
      _disconnectTimer = null;
      _flapTimer?.cancel();
      _flapTimer = null;

      if (!_flapWindowPassed) {
        _disconnectShown = false;
        return;
      }

      if (_disconnectShown) {
        _emitOnce(WsNoticeType.reconnected, '연결이 복구됐어요');
        _disconnectShown = false;
      }
    }
  }

  void _emitOnce(WsNoticeType type, String message) {
    if (_cooldownActive && _lastType == type) return;
    _lastType = type;
    _cooldownActive = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(milliseconds: 1200), () {
      _cooldownActive = false;
    });
    state = WsNotice(type: type, message: message, tsMs: DateTime.now().millisecondsSinceEpoch);
  }
}

final wsStaleRecoveryProvider = Provider<WsStaleRecovery>((ref) {
  final r = WsStaleRecovery(ref);
  ref.onDispose(r.dispose);
  return r;
});

class WsStaleRecovery {
  final Ref _ref;
  Timer? _staleTimer;
  Timer? _rejoinTimer;
  int _armedEpoch = 0;

  WsStaleRecovery(this._ref) {
    _ref.listen<WsConnectionState>(wsConnectionProvider, (prev, next) {
      if (prev?.epoch != next.epoch || next.status != WsConnStatus.connected) {
        _cancel();
      }
      _maybeArm();
    });
    _ref.listen<int>(wsServerHelloEpochProvider, (prev, next) {
      _cancel();
      _maybeArm();
    });
    _ref.listen<MatchSyncState>(matchSyncProvider, (prev, next) {
      if (prev?.lastMatchState != next.lastMatchState) {
        _cancel();
      }
      _maybeArm();
    });
  }

  void _maybeArm() {
    final ws = _ref.read(wsConnectionProvider);
    final serverHelloEpoch = _ref.read(wsServerHelloEpochProvider);
    final hasSnapshot = _ref.read(matchSyncProvider).lastMatchState != null;
    if (ws.status != WsConnStatus.connected) return;
    if (serverHelloEpoch != ws.epoch) return;
    if (hasSnapshot) return;

    if (_staleTimer != null) return;
    _armedEpoch = ws.epoch;
    _staleTimer = Timer(const Duration(seconds: 4), _onStale);
  }

  void _onStale() {
    _staleTimer = null;
    if (!_ref.mounted) return;

    final ws = _ref.read(wsConnectionProvider);
    final serverHelloEpoch = _ref.read(wsServerHelloEpochProvider);
    final sync = _ref.read(matchSyncProvider);
    final room = _ref.read(roomProvider);
    final matchId = sync.currentMatchId ?? sync.lastMatchState?.payload.matchId;

    final stillAwaiting = ws.status == WsConnStatus.connected &&
        serverHelloEpoch == ws.epoch &&
        ws.epoch == _armedEpoch &&
        sync.lastMatchState == null;
    if (!stillAwaiting) return;
    if (matchId == null || matchId.isEmpty || room.myId.isEmpty) return;

    final req = buildRequestSync(
      matchId: matchId,
      playerId: room.myId,
      lastSeq: sync.lastSeq,
      reason: 'STALE_SNAPSHOT',
    );
    _ref.read(wsClientProvider).sendEnvelope(req, (p) => p);

    _rejoinTimer?.cancel();
    _rejoinTimer = Timer(const Duration(seconds: 3), _onRejoinTimeout);
  }

  void _onRejoinTimeout() {
    _rejoinTimer = null;
    if (!_ref.mounted) return;

    final ws = _ref.read(wsConnectionProvider);
    final serverHelloEpoch = _ref.read(wsServerHelloEpochProvider);
    final sync = _ref.read(matchSyncProvider);

    final stillAwaiting =
        ws.status == WsConnStatus.connected && serverHelloEpoch == ws.epoch && sync.lastMatchState == null;
    if (!stillAwaiting) return;

    _ref.read(wsConnectionProvider.notifier).forceReconnect();
  }

  void _cancel() {
    _staleTimer?.cancel();
    _staleTimer = null;
    _rejoinTimer?.cancel();
    _rejoinTimer = null;
  }

  void dispose() => _cancel();
}
