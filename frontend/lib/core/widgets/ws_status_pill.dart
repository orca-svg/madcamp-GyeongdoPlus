import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../net/ws/ws_client.dart';

String wsConnectionStatusText({
  required WsConnectionState wsConn,
  required int serverHelloEpoch,
  required bool hasSnapshot,
}) {
  switch (wsConn.status) {
    case WsConnStatus.connecting:
    case WsConnStatus.reconnecting:
      return '연결 중…';
    case WsConnStatus.disconnected:
      return '연결 안됨';
    case WsConnStatus.connected:
      if (serverHelloEpoch != wsConn.epoch) return '서버 확인 중…';
      if (!hasSnapshot) return '동기화 대기 중…';
      return '동기화 완료';
  }
}

class WsStatusPill extends StatelessWidget {
  final String text;

  const WsStatusPill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = switch (text) {
      '동기화 완료' => AppColors.lime,
      '연결 안됨' => AppColors.textMuted,
      _ => AppColors.borderCyan,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}