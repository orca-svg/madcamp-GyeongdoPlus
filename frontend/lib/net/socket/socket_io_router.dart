import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'socket_io_client_provider.dart';

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

    // TODO: Route events to appropriate providers
    // For now, just log them
    switch (event.name) {
      case 'joined_room':
        debugPrint(
          '[SOCKET.IO][ROUTER] Joined room: ${event.payload['matchId']}',
        );
        break;
      case 'player_moved':
        debugPrint(
          '[SOCKET.IO][ROUTER] Player moved: ${event.payload['userId']}',
        );
        break;
      case 'user_arrested':
        debugPrint(
          '[SOCKET.IO][ROUTER] User arrested: ${event.payload['targetUserId']}',
        );
        break;
      case 'user_rescued':
        debugPrint(
          '[SOCKET.IO][ROUTER] User rescued: ${event.payload['rescuedUserIds']}',
        );
        break;
      case 'game_over':
        debugPrint(
          '[SOCKET.IO][ROUTER] Game over: ${event.payload['winnerTeam']}',
        );
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
        debugPrint('[SOCKET.IO][ROUTER] Lobby/Room event: ${event.name}');
        break;
      default:
        debugPrint('[SOCKET.IO][ROUTER] Unhandled event: ${event.name}');
    }
  }

  void dispose() {
    _eventSub.cancel();
    _connSub?.close();
  }
}
