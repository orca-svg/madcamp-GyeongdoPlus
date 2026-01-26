import 'package:flutter/material.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/delta_chip.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, AppDimens.bottomBarHOff + 12),
            children: [
              Text('전적', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('최근 경기 기록', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 14),
              _matchCard(
                date: '2026.01.24',
                mode: '랭크 매치',
                players: '5인',
                result: '승리',
                lpDelta: 25,
                kda: '12/3/8',
                accent: AppColors.lime,
              ),
              const SizedBox(height: 12),
              _matchCard(
                date: '2026.01.23',
                mode: '일반 매치',
                players: '5인',
                result: '패배',
                lpDelta: -12,
                kda: '8/6/4',
                accent: AppColors.red,
              ),
              const SizedBox(height: 12),
              _matchCard(
                date: '2026.01.21',
                mode: '랭크 매치',
                players: '4인',
                result: '승리',
                lpDelta: 18,
                kda: '10/2/7',
                accent: AppColors.borderCyan,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchCard({
    required String date,
    required String mode,
    required String players,
    required String result,
    required int lpDelta,
    required String kda,
    required Color accent,
  }) {
    return GlowCard(
      glow: true,
      glowColor: accent.withOpacity(0.12),
      borderColor: accent.withOpacity(0.35),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.25)),
            ),
            child: Icon(result == '승리' ? Icons.emoji_events_rounded : Icons.close_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$mode • $players', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Text('K/D/A: $kda', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                result,
                style: TextStyle(color: accent, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              DeltaChip(delta: lpDelta.toDouble(), suffix: ' LP'),
            ],
          ),
        ],
      ),
    );
  }
}

