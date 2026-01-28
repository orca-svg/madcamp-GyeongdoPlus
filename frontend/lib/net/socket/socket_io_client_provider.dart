import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/env.dart';

enum SocketIoConnStatus { disconnected, connecting, connected, reconnecting }

class SocketIoConnectionState {
  final SocketIoConnStatus status;
  final String? lastError;
  final int epoch;

  const SocketIoConnectionState({
    required this.status,
    required this.lastError,
    required this.epoch,
  });

  factory SocketIoConnectionState.initial() => const SocketIoConnectionState(
    status: SocketIoConnStatus.disconnected,
    lastError: null,
    epoch: 0,
  );

  SocketIoConnectionState copyWith({
    SocketIoConnStatus? status,
    String? lastError,
    int? epoch,
  }) {
    return SocketIoConnectionState(
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      epoch: epoch ?? this.epoch,
    );
  }
}

/// Socket.IO client for backend communication
final socketIoClientProvider =
    NotifierProvider<SocketIoController, SocketIoConnectionState>(
      SocketIoController.new,
    );

class SocketIoController extends Notifier<SocketIoConnectionState> {
  io.Socket? _socket;
  final _eventCtrl = StreamController<SocketIoEvent>.broadcast();
  int _epoch = 0;

  Stream<SocketIoEvent> get events => _eventCtrl.stream;

  @override
  SocketIoConnectionState build() {
    ref.onDispose(_dispose);
    return SocketIoConnectionState.initial();
  }

  Future<void> connect({required String? jwtToken, String? matchId}) async {
    if (_socket != null && _socket!.connected) {
      debugPrint('[SOCKET.IO] Already connected');
      return;
    }

    final baseUrl = Env.socketIoUrl;
    state = state.copyWith(status: SocketIoConnStatus.connecting);
    _epoch += 1;

    final completer = Completer<void>();

    try {
      _socket = io.io(
        '$baseUrl/game', // Add /game namespace
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'origin': baseUrl})
            .setAuth(jwtToken != null ? {'token': jwtToken} : {})
            .setQuery(matchId != null ? {'matchId': matchId} : {})
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(10000)
            .build(),
      );

      _setupListeners(completer);
      _socket!.connect();

      debugPrint('[SOCKET.IO] Connecting to $baseUrl/game');

      // Wait for connection or timeout (e.g. 5 seconds)
      // We don't want to block indefinitely if server is down,
      // but we should give it a chance to connect for correct sequencing.
      try {
        await completer.future.timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('[SOCKET.IO] Connect timeout or error: $e');
        // We don't throw here, just let it continue in background
        // The state will remain 'connecting' or turn 'disconnected' via listeners
      }
    } catch (e) {
      debugPrint('[SOCKET.IO] Connection error: $e');
      state = state.copyWith(
        status: SocketIoConnStatus.disconnected,
        lastError: e.toString(),
      );
    }
  }

  void _setupListeners(Completer<void> completer) {
    final socket = _socket;
    if (socket == null) return;

    socket.onConnect((_) {
      debugPrint('[SOCKET.IO] Connected (epoch=$_epoch)');
      state = state.copyWith(
        status: SocketIoConnStatus.connected,
        lastError: null,
        epoch: _epoch,
      );
      if (!completer.isCompleted) completer.complete();
    });

    socket.onDisconnect((_) {
      debugPrint('[SOCKET.IO] Disconnected');
      state = state.copyWith(status: SocketIoConnStatus.disconnected);
    });

    socket.onConnectError((error) {
      debugPrint('[SOCKET.IO] Connection error: $error');
      state = state.copyWith(
        status: SocketIoConnStatus.disconnected,
        lastError: error.toString(),
      );
      if (!completer.isCompleted) completer.completeError(error);
    });

    socket.onError((error) {
      debugPrint('[SOCKET.IO] Error: $error');
      state = state.copyWith(lastError: error.toString());
    });

    socket.onReconnectAttempt((attempt) {
      debugPrint('[SOCKET.IO] Reconnect attempt: $attempt');
      state = state.copyWith(status: SocketIoConnStatus.reconnecting);
    });

    // Register all server events
    _registerServerEvents();
  }

  void _registerServerEvents() {
    final socket = _socket;
    if (socket == null) return;

    // List of all server → client events from backend
    const serverEvents = [
      'joined_room',
      'user_joined', // Critical for Host to see new joiners
      'player_moved',
      'user_arrested',
      'user_rescued',
      'game_over',
      'host_changed',
      'user_left',
      'radar_activated',
      'detector_vibrate',
      'reveal_thieves_static',
      'reveal_police_static',
      'police_revealed_by_decoy',
      'emp_activated',
      'ability_silenced',
      'rescue_blocked',
      'play_siren',
      'reset_channeling',
      'clown_taunt',
      'settings_updated',
      'member_updated',
      'room_updated',
      'team_changed',
    ];

    for (final eventName in serverEvents) {
      socket.on(eventName, (data) {
        debugPrint('[SOCKET.IO] Event received: $eventName');
        final payload = data is Map<String, dynamic>
            ? data
            : (data is List && data.isNotEmpty && data[0] is Map
                  ? (data[0] as Map).cast<String, dynamic>()
                  : <String, dynamic>{});

        _eventCtrl.add(
          SocketIoEvent(
            name: eventName,
            payload: payload,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  void emit(String event, Map<String, dynamic> data) {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      debugPrint('[SOCKET.IO] Cannot emit $event: not connected');
      return;
    }

    debugPrint('[SOCKET.IO] Emitting: $event');
    socket.emit(event, data);
  }

  void emitJoinRoom(String matchId) {
    emit('join_room', {'matchId': matchId});
  }

  Future<void> disconnect() async {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    state = state.copyWith(
      status: SocketIoConnStatus.disconnected,
      lastError: null,
    );
    debugPrint('[SOCKET.IO] Disconnected manually');
  }

  void _dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _eventCtrl.close();
  }
}

class SocketIoEvent {
  final String name;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  const SocketIoEvent({
    required this.name,
    required this.payload,
    required this.timestamp,
  });
}
