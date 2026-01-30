import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'socket_io_client_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/game_phase_provider.dart';

final socketIoRouterProvider = Provider<SocketIoRouter>((ref) {
  final router = SocketIoRouter(ref);
  ref.onDispose(router.dispose);
  return router;
});

class SocketIoRouter {
  final Ref _ref;
  late final StreamSubscription<SocketIoEvent> _eventSub;
  ProviderSubscription<SocketIoConnectionState>? _connSub;

  SocketIoRouter(this._ref) {
    final client = _ref.read(socketIoClientProvider.notifier);

    _eventSub = client.events.listen(_onEvent);
    _connSub = _ref.listen(socketIoClientProvider, (prev, next) {
      if (next.status == SocketIoConnStatus.connected) {
        debugPrint('[SOCKET.IO][ROUTER] Connected');
      } else if (next.status == SocketIoConnStatus.disconnected) {
        debugPrint('[SOCKET.IO][ROUTER] Disconnected');
      }
    });
  }

  void _onEvent(SocketIoEvent event) {
    debugPrint('[SOCKET.IO][ROUTER] Event: ${event.name} - ${event.payload}');

    try {
      switch (event.name) {
        case 'joined_room':
          _handleJoinedRoom(event.payload);
          break;
        case 'player_moved':
          _handlePlayerMoved(event.payload);
          break;
        case 'user_arrested':
          _handleUserArrested(event.payload);
          break;
        case 'user_rescued':
          _handleUserRescued(event.payload);
          break;
        case 'game_over':
          _handleGameOver(event.payload);
          break;
        case 'user_joined':
        case 'user_left':
        case 'room_updated':
        case 'settings_updated':
        case 'member_updated':
        case 'team_changed':
        case 'role_changed':
        case 'ready_changed':
        case 'player_ready':
        case 'member_ready':
        case 'full_rules_update':
        case 'host_changed':
        case 'new_host':
          _handleRoomEvent(event.name, event.payload);
          break;
        default:
          debugPrint('[SOCKET.IO][ROUTER] Unhandled event: ${event.name}');
      }
    } catch (e, stackTrace) {
      debugPrint('[SOCKET.IO][ROUTER] Error handling event ${event.name}: $e');
      debugPrint('[SOCKET.IO][ROUTER] Stack trace: $stackTrace');
    }
  }

  void _handleJoinedRoom(Map<String, dynamic> payload) {
    debugPrint('[SOCKET.IO][ROUTER] Joined room: ${payload['matchId']}');
    // Room provider should already be in lobby state from REST API join
    // This confirms Socket.IO connection is established
  }

  void _handlePlayerMoved(Map<String, dynamic> payload) {
    debugPrint('[SOCKET.IO][ROUTER] Player moved: ${payload['userId']}');
    // Position updates are handled by WebSocket telemetry, not Socket.IO
    // This is a duplicate channel and can be safely ignored
  }

  void _handleUserArrested(Map<String, dynamic> payload) {
    debugPrint('[SOCKET.IO][ROUTER] User arrested: ${payload['targetUserId']}');
    // Arrest events should be reflected in match_state via WebSocket
    // Socket.IO provides redundant notification
    // TODO: Add haptic feedback or UI notification here if needed
  }

  void _handleUserRescued(Map<String, dynamic> payload) {
    debugPrint('[SOCKET.IO][ROUTER] User rescued: ${payload['rescuedUserIds']}');
    // Rescue events should be reflected in match_state via WebSocket
    // TODO: Add haptic feedback or UI notification here if needed
  }

  void _handleGameOver(Map<String, dynamic> payload) {
    debugPrint('[SOCKET.IO][ROUTER] Game over: ${payload['winnerTeam']}');
    // Game over should trigger phase transition via WebSocket match_state
    // This is a backup signal - only use if WebSocket didn't already trigger it
    final currentPhase = _ref.read(gamePhaseProvider);
    if (currentPhase == GamePhase.inGame) {
      debugPrint('[SOCKET.IO][ROUTER] Triggering postGame phase from Socket.IO game_over');
      _ref.read(gamePhaseProvider.notifier).toPostGame();
    }
  }

  void _handleRoomEvent(String eventName, Map<String, dynamic> payload) {
    debugPrint('[SOCKET.IO][ROUTER] Room event: $eventName');

    // Notify room provider to refresh state
    // The room provider should handle these events by syncing with server
    if (_ref.read(roomProvider).inRoom) {
      debugPrint('[SOCKET.IO][ROUTER] Triggering room state refresh for event: $eventName');
      // Room provider can listen to these events and trigger a state sync
      // For now, just log - the WebSocket channel should handle most updates
    }
  }

  void dispose() {
    _eventSub.cancel();
    _connSub?.close();
  }
}
