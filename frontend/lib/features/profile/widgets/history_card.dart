import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/room_provider.dart'; // For Team enum

class HistoryCard extends StatelessWidget {
  final bool isWin;
  final Team teamType;
  final int scoreDelta; // Positive, negative, or zero
  final String date;
  final String resultText; // e.g., "경찰 승리", "도둑 검거 실패"

  const HistoryCard({
    super.key,
    required this.isWin,
    required this.teamType,
    required this.scoreDelta,
    required this.date,
    required this.resultText,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = teamType == Team.police
        ? AppColors.borderCyan
        : AppColors.red;

    // Win: Neon Glow | Loss: Grey Border
    final boxDecoration = isWin
        ? BoxDecoration(
            color: teamColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: teamColor.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: teamColor.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          )
        : BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4A4A4A)),
          );

    return Container(
      decoration: boxDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 1. Team Icon
          Icon(
            teamType == Team.police ? Icons.shield_rounded : Icons.lock_rounded,
            color: isWin ? teamColor : const Color(0xFF888888),
            size: 20,
          ),
          const SizedBox(width: 12),

          // 2. Result Text & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resultText,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // 3. Score Delta with Icon
          _buildScoreDelta(),
        ],
      ),
    );
  }

  Widget _buildScoreDelta() {
    IconData icon;
    Color color;

    if (scoreDelta > 0) {
      icon = Icons.arrow_upward_rounded;
      color = Colors.green;
    } else if (scoreDelta < 0) {
      icon = Icons.arrow_downward_rounded;
      color = AppColors.red;
    } else {
      icon = Icons.remove_rounded;
      color = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineLow),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            (scoreDelta > 0 ? '+' : '') + scoreDelta.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
