// Profile UI: compact neon ranks with consistent Home styling.
// Why: unify rank cards, show explicit "랭크명 · 점수" text, and reduce overflow risk.
// Uses RankNeonCard for police/thief with cyan/red neon borders.
// Keeps existing stats/achievements layout intact.
// Preserves neon header/gradients for profile identity.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/rank_utils.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/rank_neon_card.dart';
import '../../data/dto/user_dto.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/user_provider.dart';

const neonCyan = Color(0xFF00E5FF);
const neonPurple = Color(0xFFB026FF);
const neonLime = Color(0xFF39FF14);
const neonAmber = Color(0xFFFFD60A);
const neonPink = Color(0xFFFF2E93);
const neonOrange = Color(0xFFFF8800);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final phase = ref.watch(gamePhaseProvider);

    // Use real user data from UserProvider
    // Calculate Summary Stats
    final totalCatch = userState.totalCatch;
    final totalRelease = userState.profile?.stat.totalRelease ?? 0;

    // Calculate Rates using history data
    final historyStats = ref.read(userProvider.notifier).calculatedStats;
    final policeGames = historyStats['policeGames'] ?? 0;
    final thiefGames = historyStats['thiefGames'] ?? 0;

    final arrestRate = policeGames > 0
        ? ((totalCatch / policeGames) * 100).clamp(0.0, 100.0)
        : 0.0;

    final rescueRate = thiefGames > 0
        ? ((totalRelease / thiefGames) * 100).clamp(0.0, 100.0)
        : 0.0;

    final nickname = userState.nickname;
    final policeScore = userState.policeMmr;
    final thiefScore = userState.thiefMmr;
    final mannerScore = userState.integrityScore;
    // Removed duplicate totalRelease definition
    final totalPlaySec = userState.totalSurvival;

    final bottomInset =
        (phase == GamePhase.offGame
            ? AppDimens.bottomBarHOff
            : AppDimens.bottomBarHIn) +
        MediaQuery.of(context).padding.bottom +
        20;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 60, 20, bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Header (with background)
              GlowCard(
                glow: true,
                glowColor: neonCyan.withOpacity(0.3),
                borderColor: neonCyan.withOpacity(0.4),
                blurRadius: 8,
                padding: const EdgeInsets.all(20),
                child: _buildNewHeader(
                  context,
                  nickname,
                  mannerScore,
                  policeScore,
                  thiefScore,
                ),
              ),
              const SizedBox(height: 28),

              // 2. Rank Cards (Side by Side)
              Row(
                children: [
                  Expanded(
                    child: RankNeonCard(
                      title: 'POLICE',
                      score: policeScore,
                      icon: Icons.local_police_rounded,
                      accent: neonCyan,
                      rankName: RankUtils.getPoliceRankTitle(policeScore),
                      trend: RankTrend.none,
                      isWin: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RankNeonCard(
                      title: 'THIEF',
                      score: thiefScore,
                      icon: Icons.directions_run_rounded,
                      accent: AppColors.red,
                      rankName: RankUtils.getThiefRankTitle(thiefScore),
                      trend: RankTrend.none,
                      isWin: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Achievements (Horizontal Scroll)
              Text(
                '업적',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  itemCount: _buildAchievements(userState.achievements).length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final achievement = _buildAchievements(
                      userState.achievements,
                    )[index];
                    return SizedBox(
                      width: 140,
                      child: GlowCard(
                        glow: achievement.unlocked,
                        glowColor: neonAmber,
                        blurRadius: achievement.unlocked ? 10 : 0,
                        borderColor: achievement.unlocked
                            ? neonAmber.withOpacity(0.6)
                            : const Color(0xFF333333),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              achievement.unlocked
                                  ? Icons.emoji_events_rounded
                                  : Icons.lock_outline_rounded,
                              color: achievement.unlocked
                                  ? neonAmber
                                  : const Color(0xFF666666),
                              size: 28,
                            ),
                            Text(
                              achievement.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: achievement.unlocked
                                    ? AppColors.textPrimary
                                    : const Color(0xFF666666),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // 4. Summary Grid (with background and reduced spacing)
              Text(
                '요약',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8), // Tighter gap between title and grid
              _buildSummaryGrid(
                totalPlaySec,
                userState.totalDistance,
                totalCatch,
                totalRelease,
                arrestRate,
                rescueRate,
              ),
              const SizedBox(height: 40),

              // 5. Logout Button
              _buildLogoutButton(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewHeader(
    BuildContext context,
    String nickname,
    int mannerScore,
    int policeScore,
    int thiefScore,
  ) {
    // Determine Main Rank (Higher Score)
    final isPoliceMain = policeScore >= thiefScore;
    final mainRankTitle = isPoliceMain
        ? RankUtils.getPoliceRankTitle(policeScore)
        : RankUtils.getThiefRankTitle(thiefScore);
    final mainRankColor = isPoliceMain ? neonCyan : AppColors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Nickname
            Text(
              nickname,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
                height: 1.2,
              ),
            ),
            const Spacer(),
            // Main Rank Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: mainRankColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: mainRankColor.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: mainRankColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Text(
                mainRankTitle,
                style: TextStyle(
                  color: mainRankColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Manner Score Bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '매너 점수',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$mannerScore점',
                  style: TextStyle(
                    color: mannerScore == 0
                        ? Colors.grey
                        : Color.lerp(
                            Colors.redAccent,
                            neonLime,
                            mannerScore / 100,
                          ),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (mannerScore / 100).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFF2A2A2A),
                valueColor: AlwaysStoppedAnimation<Color>(
                  mannerScore == 0
                      ? Colors.grey
                      : Color.lerp(
                          Colors.redAccent,
                          neonLime,
                          (mannerScore / 100).clamp(0.0, 1.0),
                        )!,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(
    int playTimeSec,
    double distanceKm,
    int totalCatch,
    int totalRelease,
    double arrestRate, // Added
    double rescueRate, // Added
  ) {
    // Format play time
    final hours = playTimeSec ~/ 3600;
    final minutes = (playTimeSec % 3600) ~/ 60;
    final timeStr = '${hours}h ${minutes}m';

    // Format distance
    final distStr = '${distanceKm.toStringAsFixed(1)}km';

    // Format rates
    final arrestStr = '${arrestRate.toStringAsFixed(1)}%';
    final rescueStr = '${rescueRate.toStringAsFixed(1)}%';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12, // Reduced spacing
      crossAxisSpacing: 12,
      childAspectRatio: 1.5, // Make cards wider
      children: [
        _buildStatItem('플레이 시간', timeStr, Icons.timer_outlined, neonPink),
        _buildStatItem('이동 거리', distStr, Icons.map_outlined, neonAmber),
        _buildStatItem(
          '검거율 ($totalCatch회)', // Show count in label
          arrestStr,
          Icons.security_outlined,
          neonCyan,
        ),
        _buildStatItem(
          '해방율 ($totalRelease회)', // Show count in label
          rescueStr,
          Icons.lock_open_outlined,
          neonPurple,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          ref.read(authProvider.notifier).signOut();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          side: const BorderSide(color: AppColors.red, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.red.withOpacity(0.05),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          '로그아웃',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Rank Helper methods removed in favor of RankUtils

  // Achievement ID -> Display Title Mapping
  // TODO: Verify exact IDs with backend. These are tentative.
  static const Map<String, String> _achievementMetadata = {
    'first_catch': '첫 체포',
    'first_play': '첫 경기',
    'win_streak_3': '3연승',
    'rescue_master': '구출 전문가',
    'distance_100km': '100km 달성',
    'play_10': '10경기 완주',
  };

  List<AchievementSummary> _buildAchievements(List<dynamic> dtos) {
    // 1. Get list of earned IDs
    final earnedIds = dtos.map((e) {
      if (e is AchievementDto) return e.achieveId;
      // Fallback for dynamic/mapped types
      return (e as dynamic).achieveId.toString();
    }).toSet();

    List<AchievementSummary> result = [];

    // 2. Iterate through master metadata to build the full list
    _achievementMetadata.forEach((id, title) {
      final isUnlocked = earnedIds.contains(id);
      result.add(AchievementSummary(title: title, unlocked: isUnlocked));
    });

    // 3. (Optional) Add any earned achievements that aren't in metadata
    // This ensures we always show earned stuff even if our metadata is outdated
    for (final earnedId in earnedIds) {
      if (!_achievementMetadata.containsKey(earnedId)) {
        result.add(
          AchievementSummary(
            title: earnedId, // Fallback to ID
            unlocked: true,
          ),
        );
      }
    }

    return result;
  }
}

class AchievementSummary {
  final String title;
  final bool unlocked;

  const AchievementSummary({required this.title, required this.unlocked});
}
