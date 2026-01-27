import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class WatchSyncService {
  Future<void> init();
  Future<bool> isPairedOrConnected();
  Future<void> sendStateSnapshot(Map<String, dynamic> json);
  Future<void> sendHapticAlert(Map<String, dynamic> json);
  Future<void> sendHapticCommand(Map<String, dynamic> payload);
  Stream<Map<String, dynamic>> get actionStream;
}

class AppleWatchSyncService implements WatchSyncService {
  static const MethodChannel _ch = MethodChannel('gyeongdo/watch_bridge');
  static const EventChannel _actionCh = EventChannel('gyeongdo/watch_action');

  @override
  Future<void> init() async {
    try {
      await _ch.invokeMethod('init');
    } catch (_) {}
  }

  @override
  Future<bool> isPairedOrConnected() async {
    try {
      final v = await _ch.invokeMethod('isConnected');
      return v == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> sendStateSnapshot(Map<String, dynamic> json) async {
    try {
      final jsonStr = jsonEncode(json);
      // debugPrint('[WatchSyncService] Sending Snapshot: len=${jsonStr.length}');
      await _ch.invokeMethod('sendStateSnapshot', {'json': jsonStr});
    } catch (e) {
      debugPrint('[WatchSyncService] Send Snapshot Error: $e');
    }
  }

  @override
  Future<void> sendHapticAlert(Map<String, dynamic> json) async {
    try {
      final jsonStr = jsonEncode(json);
      await _ch.invokeMethod('sendHapticAlert', {'json': jsonStr});
    } catch (_) {}
  }

  @override
  Future<void> sendHapticCommand(Map<String, dynamic> payload) async {
    await sendHapticAlert({
      'matchId': 'CMD',
      'type': 'HAPTIC_ALERT',
      'payload': {
        'kind': payload['kind'] ?? 'HEAVY',
        'cooldownSec': 0,
        'durationMs': 500,
      },
    });
  }

  @override
  Stream<Map<String, dynamic>>
  get actionStream => _actionCh.receiveBroadcastStream().map((event) {
    if (event is String) {
      try {
        final decoded = jsonDecode(event);
        if (decoded is Map) {
          final map = decoded.cast<String, dynamic>();
          final matchId = map['matchId']?.toString();
          debugPrint(
            '[WATCH][RX] Action: matchId=$matchId payload=${map['payload']}',
          );
          return map;
        }
      } catch (_) {}
    } else if (event is Map) {
      return event.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  });
}

class WearOsSyncService implements WatchSyncService {
  static const MethodChannel _ch = MethodChannel('gyeongdo/watch_bridge');
  static const EventChannel _actionCh = EventChannel('gyeongdo/watch_action');

  @override
  Future<void> init() async {
    try {
      await _ch.invokeMethod('init');
      debugPrint('[WearOsSyncService] Initialized');
    } catch (e) {
      debugPrint('[WearOsSyncService] Init error: $e');
    }
  }

  @override
  Future<bool> isPairedOrConnected() async {
    try {
      final v = await _ch.invokeMethod('isConnected');
      debugPrint('[WearOsSyncService] isConnected: $v');
      return v == true;
    } catch (e) {
      debugPrint('[WearOsSyncService] isConnected error: $e');
      return false;
    }
  }

  @override
  Future<void> sendStateSnapshot(Map<String, dynamic> json) async {
    try {
      final jsonStr = jsonEncode(json);
      await _ch.invokeMethod('sendStateSnapshot', {'json': jsonStr});
      debugPrint(
        '[WearOsSyncService] sendStateSnapshot: len=${jsonStr.length}',
      );
    } catch (e) {
      debugPrint('[WearOsSyncService] sendStateSnapshot error: $e');
    }
  }

  @override
  Future<void> sendHapticAlert(Map<String, dynamic> json) async {
    try {
      final jsonStr = jsonEncode(json);
      await _ch.invokeMethod('sendHapticAlert', {'json': jsonStr});
      debugPrint('[WearOsSyncService] sendHapticAlert sent');
    } catch (e) {
      debugPrint('[WearOsSyncService] sendHapticAlert error: $e');
    }
  }

  @override
  Future<void> sendHapticCommand(Map<String, dynamic> payload) async {
    await sendHapticAlert({
      'matchId': 'CMD',
      'type': 'HAPTIC_ALERT',
      'payload': {
        'kind': payload['kind'] ?? 'HEAVY',
        'cooldownSec': 0,
        'durationMs': 500,
      },
    });
  }

  @override
  Stream<Map<String, dynamic>> get actionStream =>
      _actionCh.receiveBroadcastStream().map((event) {
        if (event is String) {
          try {
            final decoded = jsonDecode(event);
            if (decoded is Map) {
              final map = decoded.cast<String, dynamic>();
              debugPrint(
                '[WearOsSyncService] Action received: ${map['payload']}',
              );
              return map;
            }
          } catch (_) {}
        } else if (event is Map) {
          return event.cast<String, dynamic>();
        }
        return <String, dynamic>{};
      });
}

final watchSyncServiceProvider = Provider<WatchSyncService>((ref) {
  if (Platform.isIOS) return AppleWatchSyncService();
  if (Platform.isAndroid) return WearOsSyncService();
  // Fallback for other platforms (web, desktop, etc.)
  return _StubWatchSyncService();
});

/// Stub implementation for unsupported platforms
class _StubWatchSyncService implements WatchSyncService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> isPairedOrConnected() async => false;
  @override
  Future<void> sendStateSnapshot(Map<String, dynamic> json) async {}
  @override
  Future<void> sendHapticAlert(Map<String, dynamic> json) async {}
  @override
  Future<void> sendHapticCommand(Map<String, dynamic> payload) async {}
  @override
  Stream<Map<String, dynamic>> get actionStream => const Stream.empty();
}
