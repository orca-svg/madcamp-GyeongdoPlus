// Reusable neon rank card for Home/Profile.
// Why: keep rank UI consistent and compact across tabs.
// Shows role title + computed rank name and score in separated rows.
// Border/glow colors are provided to match police/thief neon palettes.
// Includes simple score->rank mapping for placeholder data.
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glow_card.dart';

enum RankTrend { up, down, none }

class RankNeonCard extends StatelessWidget {
  final String title;
  final int score;
  final IconData icon;
  final Color accent;
  final String? rankName;
  final RankTrend trend;
  final bool isWin; // For glow control

  const RankNeonCard({
    super.key,
    required this.title,
    required this.score,
    required this.icon,
    required this.accent,
    this.rankName,
    this.trend = RankTrend.none,
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
      blurRadius: isWin ? 12 : 0,
      borderColor: borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Icon + Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
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
              Text(
                title,
                style: TextStyle(
                  color: isWin ? accent : AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (trend != RankTrend.none)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (trend == RankTrend.up
                                ? Colors.greenAccent
                                : Colors.redAccent)
                            .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend == RankTrend.up
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: trend == RankTrend.up
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Rank Name - Large and prominent
          Text(
            resolvedRank,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isWin ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          // Score - Smaller, secondary
          Row(
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: isWin ? accent : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'pts',
                style: TextStyle(
                  color: AppColors.textMuted.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _rankNameFromScore(int score) {
  if (score >= 3000) return '전문가';
  if (score >= 1500) return '숙련';
  if (score >= 600) return '초보';
  if (score > 0) return '입문';
  return 'Unranked';
}
