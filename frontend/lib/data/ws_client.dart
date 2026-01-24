import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/env.dart';

class WsClient {
  WebSocketChannel? _ch;
  StreamSubscription? _sub;

  final _streamCtrl = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _streamCtrl.stream;

  bool get isConnected => _ch != null;

  void connect() {
    if (_ch != null) return;
    _ch = WebSocketChannel.connect(Uri.parse(Env.wsUrl));
    _sub = _ch!.stream.listen((event) {
      try {
        final decoded = jsonDecode(event as String) as Map<String, dynamic>;
        _streamCtrl.add(decoded);
      } catch (_) {
        // ignore malformed payload
      }
    }, onDone: () {
      disconnect();
    }, onError: (_) {
      disconnect();
    });
  }

  void send(Map<String, dynamic> message) {
    final ch = _ch;
    if (ch == null) return;
    ch.sink.add(jsonEncode(message));
  }

  void disconnect() {
    _sub?.cancel();
    _sub = null;
    _ch?.sink.close();
    _ch = null;
  }

  void dispose() {
    disconnect();
    _streamCtrl.close();
  }
}
