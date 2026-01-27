import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../net/ws/ws_client.dart';
import '../net/ws/ws_client_provider.dart';
import 'match_sync_provider.dart';

enum WsUiStatus {
  disconnected,
  connecting,
  awaitingServerHello,
  awaitingSnapshot,
  synced,
}

class WsUiStatusModel {
  final WsUiStatus status;
  final String text;
  final Color dotColor;
  final bool showReconnect;
  final String? lastRawEvent;
  final String? lastRawJson;

  const WsUiStatusModel({
    required this.status,
    required this.text,
    required this.dotColor,
    required this.showReconnect,
    this.lastRawEvent,
    this.lastRawJson,
  });

  bool get isSynced => status == WsUiStatus.synced;

  WsUiStatusModel copyWith({
    WsUiStatus? status,
    String? text,
    Color? dotColor,
    bool? showReconnect,
    String? lastRawEvent,
    String? lastRawJson,
  }) {
    return WsUiStatusModel(
      status: status ?? this.status,
      text: text ?? this.text,
      dotColor: dotColor ?? this.dotColor,
      showReconnect: showReconnect ?? this.showReconnect,
      lastRawEvent: lastRawEvent ?? this.lastRawEvent,
      lastRawJson: lastRawJson ?? this.lastRawJson,
    );
  }
}

final wsUserReconnectIntentProvider =
    NotifierProvider<WsUserReconnectIntentController, bool>(
      WsUserReconnectIntentController.new,
    );

class WsUserReconnectIntentController extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    return false;
  }

  void arm(Duration d) {
    _timer?.cancel();
    state = true;
    _timer = Timer(d, () {
      if (!ref.mounted) return;
      state = false;
    });
  }

  void clear() {
    _timer?.cancel();
    _timer = null;
    state = false;
  }
}

WsUiStatusModel deriveWsUiStatus({
  required WsConnectionState wsConn,
  required int serverHelloEpoch,
  required bool hasSnapshot,
  required bool userReconnectIntent,
}) {
  switch (wsConn.status) {
    case WsConnStatus.disconnected:
      if (userReconnectIntent) {
        return const WsUiStatusModel(
          status: WsUiStatus.connecting,
          text: '재연결 중…',
          dotColor: AppColors.borderCyan,
          showReconnect: false,
        );
      }
      return const WsUiStatusModel(
        status: WsUiStatus.disconnected,
        text: '연결 안됨',
        dotColor: AppColors.textMuted,
        showReconnect: true,
      );
    case WsConnStatus.connecting:
    case WsConnStatus.reconnecting:
      return const WsUiStatusModel(
        status: WsUiStatus.connecting,
        text: '연결 중…',
        dotColor: AppColors.borderCyan,
        showReconnect: false,
      );
    case WsConnStatus.connected:
      if (serverHelloEpoch != wsConn.epoch) {
        return const WsUiStatusModel(
          status: WsUiStatus.awaitingServerHello,
          text: '서버 확인 중…',
          dotColor: AppColors.borderCyan,
          showReconnect: false,
        );
      }
      if (!hasSnapshot) {
        return const WsUiStatusModel(
          status: WsUiStatus.awaitingSnapshot,
          text: '동기화 대기 중…',
          dotColor: AppColors.borderCyan,
          showReconnect: false,
        );
      }
      return const WsUiStatusModel(
        status: WsUiStatus.synced,
        text: '동기화 완료',
        dotColor: AppColors.lime,
        showReconnect: false,
      );
  }
}

final wsUiStatusProvider = Provider<WsUiStatusModel>((ref) {
  final wsConn = ref.watch(wsConnectionProvider);
  final serverHelloEpoch = ref.watch(wsServerHelloEpochProvider);
  final hasSnapshot = ref.watch(matchSyncProvider).lastMatchState != null;
  final intent = ref.watch(wsUserReconnectIntentProvider);

  return deriveWsUiStatus(
    wsConn: wsConn,
    serverHelloEpoch: serverHelloEpoch,
    hasSnapshot: hasSnapshot,
    userReconnectIntent: intent,
  );
});
