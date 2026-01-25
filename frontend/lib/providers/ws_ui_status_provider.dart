import 'package:flutter/material.dart';
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

  const WsUiStatusModel({
    required this.status,
    required this.text,
    required this.dotColor,
    required this.showReconnect,
  });

  bool get isSynced => status == WsUiStatus.synced;
}

final wsUiStatusProvider = Provider<WsUiStatusModel>((ref) {
  final wsConn = ref.watch(wsConnectionProvider);
  final serverHelloEpoch = ref.watch(wsServerHelloEpochProvider);
  final hasSnapshot = ref.watch(matchSyncProvider).lastMatchState != null;

  switch (wsConn.status) {
    case WsConnStatus.disconnected:
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
});

