import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'ws_envelope.dart';

enum WsConnStatus { disconnected, connecting, connected, reconnecting }

class WsConnectionState {
  final WsConnStatus status;
  final int reconnectAttempt;
  final String? lastError;
  final int epoch;

  const WsConnectionState({
    required this.status,
    required this.reconnectAttempt,
    required this.lastError,
    required this.epoch,
  });

  factory WsConnectionState.initial() => const WsConnectionState(
        status: WsConnStatus.disconnected,
        reconnectAttempt: 0,
        lastError: null,
        epoch: 0,
      );

  WsConnectionState copyWith({WsConnStatus? status, int? reconnectAttempt, String? lastError, int? epoch}) {
    return WsConnectionState(
      status: status ?? this.status,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      lastError: lastError ?? this.lastError,
      epoch: epoch ?? this.epoch,
    );
  }
}

class WsClient {
  WebSocketChannel? _ch;
  StreamSubscription? _sub;

  final _envelopeCtrl = StreamController<WsEnvelope<Object?>>.broadcast();
  Stream<WsEnvelope<Object?>> get envelopes => _envelopeCtrl.stream;

  final _connCtrl = StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get connection => _connCtrl.stream;
  WsConnectionState _connState = WsConnectionState.initial();
  WsConnectionState get connectionState => _connState;

  Uri? _url;
  Map<String, String>? _headers;

  bool _manualDisconnect = false;
  Timer? _reconnectTimer;
  final _rng = Random();
  int _epoch = 0;

  bool get isConnected => _ch != null && _connState.status == WsConnStatus.connected;

  Future<void> connect({
    required Uri url,
    Map<String, String>? headers,
  }) async {
    _url = url;
    _headers = headers;
    _manualDisconnect = false;

    if (_ch != null) return;
    _setConn(_connState.copyWith(status: WsConnStatus.connecting, lastError: null));
    _open();
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _close();
    _setConn(_connState.copyWith(
      status: WsConnStatus.disconnected,
      reconnectAttempt: 0,
      lastError: null,
    ));
  }

  void sendEnvelope<T>(WsEnvelope<T> env, Map<String, dynamic> Function(T) payloadToJson) {
    final ch = _ch;
    if (ch == null) return;
    ch.sink.add(jsonEncode(env.toJson(payloadToJson)));
  }

  void _open() {
    final url = _url;
    if (url == null) return;

    _epoch += 1;

    try {
      _ch = IOWebSocketChannel.connect(url, headers: _headers);
    } catch (e) {
      _onSocketError(e);
      return;
    }

    _sub = _ch!.stream.listen(
      _onMessage,
      onDone: _onSocketDone,
      onError: _onSocketError,
      cancelOnError: true,
    );

    _setConn(_connState.copyWith(
      status: WsConnStatus.connected,
      reconnectAttempt: 0,
      lastError: null,
      epoch: _epoch,
    ));
  }

  Future<void> _close() async {
    await _sub?.cancel();
    _sub = null;
    await _ch?.sink.close();
    _ch = null;
  }

  void _onMessage(dynamic event) {
    try {
      final raw = event is String ? event : utf8.decode(event as List<int>);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final env = WsEnvelope.fromJson<Object?>(
        json: decoded.cast<String, dynamic>(),
        payloadFromJson: (rawPayload) => rawPayload,
      );
      _envelopeCtrl.add(env);
    } catch (_) {
      // ignore malformed payload
    }
  }

  void _onSocketDone() {
    _setConn(_connState.copyWith(status: WsConnStatus.disconnected));
    _cleanupAfterDrop();
  }

  void _onSocketError(Object error) {
    _setConn(_connState.copyWith(status: WsConnStatus.disconnected, lastError: error.toString()));
    _cleanupAfterDrop();
  }

  void _cleanupAfterDrop() {
    _sub?.cancel();
    _sub = null;
    _ch = null;
    if (_manualDisconnect) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final attempt = _connState.reconnectAttempt + 1;
    final base = min(20, pow(2, attempt).toInt()); // 2,4,8,16,20...
    final jitterMs = _rng.nextInt(700);
    final delay = Duration(seconds: base) + Duration(milliseconds: jitterMs);

    _setConn(_connState.copyWith(status: WsConnStatus.reconnecting, reconnectAttempt: attempt));
    _reconnectTimer = Timer(delay, _open);
  }

  void _setConn(WsConnectionState s) {
    _connState = s;
    _connCtrl.add(s);
  }

  Future<void> dispose() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _close();
    await _envelopeCtrl.close();
    await _connCtrl.close();
  }
}
