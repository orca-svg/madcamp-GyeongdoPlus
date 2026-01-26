import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flutter <-> Native (iOS/watchOS, Android/WearOS) 브리지
///
/// - native side가 아직 구현되지 않아도 앱이 죽지 않도록 모든 호출은 try/catch로 보호합니다.
/// - Step 2~5에서 iOS/Android 플러그인이 들어오면 해당 채널을 실제로 구현합니다.
class WatchBridge {
  static const MethodChannel _ch = MethodChannel('gyeongdo/watch_bridge');
  static const EventChannel _actionCh = EventChannel('gyeongdo/watch_action');

  /// (옵션) native init hook
  static Future<void> init() async {
    try {
      await _ch.invokeMethod('init');
    } catch (_) {
      // native not ready yet
    }
  }

  /// (옵션) native 연결 상태 조회
  static Future<bool> isPairedOrConnected() async {
    try {
      final v = await _ch.invokeMethod('isConnected');
      return v == true;
    } catch (_) {
      return false;
    }
  }

  /// 워치로 상태 스냅샷(JSON) 전송
  static Future<void> sendStateSnapshot(Map<String, dynamic> json) async {
    try {
      final jsonStr = jsonEncode(json);
      await _ch.invokeMethod('sendStateSnapshot', {'json': jsonStr});
    } catch (_) {
      // native not ready yet
    }
  }

  /// 워치로 진동 트리거(JSON) 전송
  static Future<void> sendHapticAlert(Map<String, dynamic> json) async {
    try {
      final jsonStr = jsonEncode(json);
      await _ch.invokeMethod('sendHapticAlert', {'json': jsonStr});
    } catch (_) {
      // native not ready yet
    }
  }

  /// 간단 진동 (legacy/utility)
  static Future<void> sendHaptic({required String type}) async {
    try {
      await _ch.invokeMethod('sendHaptic', {'type': type});
    } catch (_) {
      // native not ready yet
    }
  }

  /// 워치 액션 스트림
  ///
  /// native가 문자열(JSON) 또는 Map으로 보내도 모두 수용합니다.
  static Stream<Map<String, dynamic>> onWatchAction() {
    return _actionCh.receiveBroadcastStream().map((event) {
      if (event is String) {
        try {
          final decoded = jsonDecode(event);
          final matchId =
              decoded is Map ? decoded['matchId']?.toString() : null;
          debugPrint(
            '[WATCH][FLUTTER][RX] WATCH_ACTION matchId=$matchId len=${event.length}',
          );
          if (decoded is Map) {
            return decoded.cast<String, dynamic>();
          }
        } catch (_) {
          debugPrint('[WATCH][FLUTTER][RX] WATCH_ACTION len=${event.length}');
          return <String, dynamic>{};
        }
      } else {
        debugPrint('[WATCH][FLUTTER][RX] WATCH_ACTION');
      }
      if (event is Map) {
        return event.cast<String, dynamic>();
      }
      return <String, dynamic>{};
    });
  }
}

class WatchBridgeService {
  const WatchBridgeService();

  Future<void> init() => WatchBridge.init();

  Future<bool> isPairedOrConnected() => WatchBridge.isPairedOrConnected();

  Future<void> sendStateSnapshot(Map<String, dynamic> json) =>
      WatchBridge.sendStateSnapshot(json);

  Future<void> sendHapticAlert(Map<String, dynamic> json) =>
      WatchBridge.sendHapticAlert(json);

  Future<void> sendHaptic({required String type}) =>
      WatchBridge.sendHaptic(type: type);

  Stream<Map<String, dynamic>> onWatchAction() => WatchBridge.onWatchAction();
}

final watchBridgeProvider = Provider<WatchBridgeService>(
  (ref) => const WatchBridgeService(),
);
