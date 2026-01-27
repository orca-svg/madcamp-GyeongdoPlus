import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/active_tab_provider.dart';
import '../providers/room_provider.dart';
import 'watch_bridge.dart';

/// WATCH_ACTION 스트림을 구독하고 폰 상태를 변경하는 핸들러
class WatchActionHandler {
  final Ref ref;
  StreamSubscription? _subscription;

  WatchActionHandler(this.ref);

  void start() {
    _subscription?.cancel();
    _subscription = ref
        .read(watchBridgeProvider)
        .onWatchAction()
        .listen(
          (event) {
            _handleAction(event);
          },
          onError: (error) {
            debugPrint('[WATCH][ACTION] Error: $error');
          },
        );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _handleAction(Map<String, dynamic> event) {
    final type = event['type']?.toString();
    if (type != 'WATCH_ACTION') return;

    final payload = event['payload'] as Map<String, dynamic>?;
    if (payload == null) return;

    final action = payload['action']?.toString();
    final value = payload['value'];

    debugPrint('[WATCH][ACTION] Received: action=$action value=$value');

    switch (action) {
      case 'OPEN_TAB':
        _handleOpenTab(value?.toString());
        break;
      case 'READY_TOGGLE':
        _handleReadyToggle();
        break;
      case 'SELECT_TEAM':
        _handleSelectTeam(value?.toString());
        break;
      case 'PING':
        _handlePing();
        break;
      default:
        debugPrint('[WATCH][ACTION] Unknown action: $action');
    }
  }

  void _handleOpenTab(String? tabWire) {
    if (tabWire == null) return;
    final tab = ActiveTabExt.fromWire(tabWire);
    if (tab != null) {
      ref.read(activeTabProvider.notifier).setTab(tab);
      debugPrint('[WATCH][ACTION] Tab changed to: ${tab.wire}');
    }
  }

  void _handleReadyToggle() {
    ref.read(roomProvider.notifier).toggleReady();
    debugPrint('[WATCH][ACTION] Ready toggled');
  }

  void _handleSelectTeam(String? teamWire) {
    if (teamWire == null) return;
    final team = teamWire.toUpperCase() == 'POLICE' ? Team.police : Team.thief;
    ref.read(roomProvider.notifier).setMyTeam(team);
    debugPrint('[WATCH][ACTION] Team selected: $teamWire');
  }

  void _handlePing() {
    // TODO: Implement ping action (e.g., send ping to server or trigger local effect)
    debugPrint('[WATCH][ACTION] Ping received');
  }
}

final watchActionHandlerProvider = Provider<WatchActionHandler>((ref) {
  final handler = WatchActionHandler(ref);
  ref.onDispose(() => handler.stop());
  return handler;
});

/// Provider to auto-start the handler
final watchActionHandlerInitProvider = Provider<void>((ref) {
  final handler = ref.watch(watchActionHandlerProvider);
  handler.start();
});
