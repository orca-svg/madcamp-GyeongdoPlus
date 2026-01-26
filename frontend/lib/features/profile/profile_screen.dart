// Profile UI: compact neon ranks with consistent Home styling.
// Why: unify rank cards, show explicit "랭크명 · 점수" text, and reduce overflow risk.
// Uses RankNeonCard for police/thief with cyan/red neon borders.
// Keeps existing stats/achievements layout intact.
// Preserves neon header/gradients for profile identity.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/rank_neon_card.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/profile_stats_provider.dart';
import '../../providers/room_provider.dart';

const neonCyan = Color(0xFF00E5FF);
const neonPurple = Color(0xFFB026FF);
const neonLime = Color(0xFF39FF14);
const neonAmber = Color(0xFFFFD60A);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(profileStatsProvider);
    final room = ref.watch(roomProvider);
    final phase = ref.watch(gamePhaseProvider);
    final nickname = room.me?.name ?? '김선수';
    final bottomInset = (phase == GamePhase.offGame
        ? AppDimens.bottomBarHOff
        : AppDimens.bottomBarHIn) +
        18;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내정보', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  '프로필 및 통계',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                _profileHeader(context, nickname),
                const SizedBox(height: 16),
                Text('랭크', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RankNeonCard(
                        title: '경찰',
                        score: stats.policeScore,
                        icon: Icons.shield_rounded,
                        accent: AppColors.borderCyan,
                        rankName: _rankNameFromScore(stats.policeScore),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RankNeonCard(
                        title: '도둑',
                        score: stats.thiefScore,
                        icon: Icons.lock_rounded,
                        accent: AppColors.red,
                        rankName: _rankNameFromScore(stats.thiefScore),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('스탯', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _statGrid(stats),
                const SizedBox(height: 18),
                Text('매너', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _mannerCard(stats),
                const SizedBox(height: 18),
                Text('업적', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _achievementRow(stats.achievements),
                const SizedBox(height: 18),
                Text('총 플레이 시간', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                GlowCard(
                  glow: true,
                  glowColor: neonCyan,
                  borderColor: neonCyan.withOpacity(0.6),
                  child: Text(
                    _formatDuration(stats.totalPlaySec),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(BuildContext context, String nickname) {
    return GlowCard(
      glow: true,
      glowColor: neonCyan,
      borderColor: neonCyan.withOpacity(0.55),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [neonCyan, neonPurple],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '오늘도 안전하게!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statGrid(ProfileStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _statCard('평균 체포 수', stats.avgCaught.toStringAsFixed(1)),
        _statCard('평균 해방 수', stats.avgRescued.toStringAsFixed(1)),
        _statCard('총 이동거리', '128.4 km'),
        _statCard('총 플레이', _formatDuration(stats.totalPlaySec)),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return GlowCard(
      glow: true,
      glowColor: neonCyan,
      borderColor: neonCyan.withOpacity(0.45),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mannerCard(ProfileStats stats) {
    final progress = stats.mannerScore / 100.0;
    return GlowCard(
      glow: true,
      glowColor: neonLime,
      borderColor: neonLime.withOpacity(0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${stats.mannerScore}점',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surface2.withOpacity(0.4),
              color: neonLime,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '경고 0회',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementRow(List<AchievementSummary> achievements) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = achievements[index];
          final accent = item.unlocked ? neonAmber : AppColors.outlineLow;
          return GestureDetector(
            onTap: () {
              showAppSnackBar(context, message: '다음 단계에서 상세 제공');
            },
            child: GlowCard(
              glow: item.unlocked,
              glowColor: accent,
              borderColor: accent.withOpacity(item.unlocked ? 0.8 : 0.4),
              child: SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.unlocked ? Icons.emoji_events_rounded : Icons.lock_rounded,
                      color: item.unlocked ? neonAmber : AppColors.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.unlocked
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(int sec) {
    final hours = sec ~/ 3600;
    final minutes = (sec % 3600) ~/ 60;
    if (hours <= 0) return '${minutes}분';
    return '${hours}시간 ${minutes}분';
  }
}

String _rankNameFromScore(int score) {
  if (score >= 1500) return '전문가';
  if (score >= 1000) return '숙련';
  return '초보';
}
