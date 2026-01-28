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
    final isActive = score > 0;

    // Inactive (0 score): Dimmed gray, no glow
    // Active (Score > 0): Neon colors based on isWin/accent
    final effectiveAccent = isActive ? accent : const Color(0xFF666666);
    final glowActive = isActive && isWin;

    final borderColor = glowActive
        ? effectiveAccent.withOpacity(0.7)
        : const Color(0xFF3A3A3A); // Darker border for inactive

    final glowColor = glowActive ? effectiveAccent : Colors.transparent;
    final iconColor = isActive ? effectiveAccent : const Color(0xFF666666);
    final iconBgColor = isActive
        ? effectiveAccent.withOpacity(0.18)
        : const Color(0xFF222222);

    return GlowCard(
      glow: glowActive,
      glowColor: glowColor,
      blurRadius: glowActive ? 12 : 0,
      borderColor: borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Icon + Title + Trend (if any)
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? effectiveAccent.withOpacity(0.5)
                        : const Color(0xFF3A3A3A),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? effectiveAccent : AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (trend != RankTrend.none && isActive)
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
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    trend == RankTrend.up
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                    color: trend == RankTrend.up
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Row: Rank Name (Left) + Score (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                resolvedRank,
                style: TextStyle(
                  color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      color: isActive ? effectiveAccent : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PTS',
                    style: TextStyle(
                      color: AppColors.textMuted.withOpacity(0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
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
