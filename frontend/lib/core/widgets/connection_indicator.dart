// Shared neon connection indicator (watch/WS/etc.).
// Why: keep a single consistent visual for connection state across screens.
// Compact pill with icon + dot + label and neon border.
// Uses AppColors to match existing neon theme.
// Designed to be small enough for title rows without overflow.
// Optional label allows reuse in radar/home without duplication.
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ConnectionIndicator extends StatelessWidget {
  final IconData icon;
  final bool connected;
  final String label;

  const ConnectionIndicator({
    super.key,
    required this.icon,
    required this.connected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.lime : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
