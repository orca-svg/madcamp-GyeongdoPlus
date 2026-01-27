// Reusable neon rank card for Home/Profile.
// Why: keep rank UI consistent and compact across tabs.
// Shows role title + computed rank name and score in "랭크명 · 점수" format.
// Border/glow colors are provided to match police/thief neon palettes.
// Includes simple score->rank mapping for placeholder data.
// Keeps layout tight to avoid overflow on small devices.
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glow_card.dart';

class RankNeonCard extends StatelessWidget {
  final String title;
  final int score;
  final IconData icon;
  final Color accent;
  final String? rankName;
  final int? trend; // 1: Up, -1: Down, 0: Same
  final bool isWin; // For glow control

  const RankNeonCard({
    super.key,
    required this.title,
    required this.score,
    required this.icon,
    required this.accent,
    this.rankName,
    this.trend = 0,
    this.isWin = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedRank = rankName ?? _rankNameFromScore(score);
    // Loss: Grayscale border, No glow
    final borderColor = isWin
        ? accent.withOpacity(0.7)
        : const Color(0xFF4A4A4A);
    final glowColor = isWin ? accent : Colors.transparent;
    final iconColor = isWin ? accent : const Color(0xFF808080);
    final iconBgColor = isWin
        ? accent.withOpacity(0.18)
        : const Color(0xFF2A2A2A);

    return GlowCard(
      glow: isWin,
      glowColor: glowColor,
      blurRadius: isWin ? 10 : 0,
      borderColor: borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isWin
                    ? accent.withOpacity(0.5)
                    : const Color(0xFF4A4A4A),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$resolvedRank · $score',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (trend != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        trend == 1
                            ? Icons.arrow_upward_rounded
                            : trend == -1
                            ? Icons.arrow_downward_rounded
                            : Icons.remove_rounded,
                        size: 14,
                        color: trend == 1
                            ? Colors.greenAccent
                            : trend == -1
                            ? Colors.redAccent
                            : Colors.grey,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _rankNameFromScore(int score) {
  if (score >= 1500) return '전문가';
  if (score >= 1000) return '숙련';
  return '초보';
}
