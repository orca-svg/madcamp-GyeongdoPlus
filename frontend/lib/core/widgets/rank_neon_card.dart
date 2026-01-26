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

  const RankNeonCard({
    super.key,
    required this.title,
    required this.score,
    required this.icon,
    required this.accent,
    this.rankName,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedRank = rankName ?? _rankNameFromScore(score);
    return GlowCard(
      glow: true,
      glowColor: accent,
      borderColor: accent.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.5)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: accent),
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
                Text(
                  '$resolvedRank · $score',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
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
