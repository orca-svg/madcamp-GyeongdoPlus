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
import '../../providers/auth_provider.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/profile_stats_provider.dart';
import '../../providers/room_provider.dart';
import 'widgets/history_card.dart';

const neonCyan = Color(0xFF00E5FF);
const neonPurple = Color(0xFFB026FF);
const neonLime = Color(0xFF39FF14);
const neonAmber = Color(0xFFFFD60A);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final room = ref.watch(roomProvider);
    final phase = ref.watch(gamePhaseProvider);

    // Use real user data from AuthProvider
    final nickname = user?.nickname ?? room.me?.name ?? '김선수';
    final policeScore = user?.policeScore ?? 0;
    final thiefScore = user?.thiefScore ?? 0;
    final totalGames = user?.totalGames ?? 0;
    final wins = user?.wins ?? 0;
    final losses = user?.losses ?? 0;
    final mannerScore = user?.mannerScore ?? 100;
    final totalPlaySec = user?.totalPlayTimeSec ?? 0;

    final bottomInset =
        (phase == GamePhase.offGame
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('내정보', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) {
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/', (route) => false);
                        }
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.textMuted,
                      ),
                      tooltip: '로그아웃',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '프로필 및 통계',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
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
                        score: policeScore,
                        icon: Icons.shield_rounded,
                        accent: AppColors.borderCyan,
                        rankName: _rankNameFromScore(policeScore),
                        trend: 1, // Mock trend: Up
                        isWin: true, // Mock win state
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RankNeonCard(
                        title: '도둑',
                        score: thiefScore,
                        icon: Icons.lock_rounded,
                        accent: AppColors.red,
                        rankName: _rankNameFromScore(thiefScore),
                        trend: -1, // Mock trend: Down
                        isWin: false, // Mock loss state
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('스탯', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _statGrid(totalGames, wins, losses, totalPlaySec),
                const SizedBox(height: 18),
                Text('매너', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _mannerCard(mannerScore),
                const SizedBox(height: 18),
                Text('업적', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _achievementRow(_mockAchievements()),
                const SizedBox(height: 18),
                Text(
                  '총 플레이 시간',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                GlowCard(
                  glow: true,
                  glowColor: neonCyan,
                  borderColor: neonCyan.withOpacity(0.6),
                  child: Text(
                    _formatDuration(totalPlaySec),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('최근 전적', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                // Mock History Data - Tappable for details
                GestureDetector(
                  onTap: () => _showHistoryDetail(context, {
                    'isWin': true,
                    'team': 'POLICE',
                    'scoreDelta': 30,
                    'date': '2024.05.20 14:00',
                    'result': '경찰 승리 (도둑 전원 검거)',
                    'mode': 'NORMAL',
                    'players': 6,
                    'duration': '15분 32초',
                    'arrests': 3,
                    'rescues': 0,
                  }),
                  child: HistoryCard(
                    isWin: true,
                    teamType: Team.police,
                    scoreDelta: 30,
                    date: '2024.05.20 14:00',
                    resultText: '경찰 승리 (도둑 전원 검거)',
                  ),
                ),
                GestureDetector(
                  onTap: () => _showHistoryDetail(context, {
                    'isWin': false,
                    'team': 'THIEF',
                    'scoreDelta': -15,
                    'date': '2024.05.19 18:30',
                    'result': '패배 (검거됨)',
                    'mode': 'NORMAL',
                    'players': 4,
                    'duration': '8분 45초',
                    'arrests': 0,
                    'rescues': 1,
                  }),
                  child: HistoryCard(
                    isWin: false,
                    teamType: Team.thief,
                    scoreDelta: -15,
                    date: '2024.05.19 18:30',
                    resultText: '패배 (검거됨)',
                  ),
                ),
                GestureDetector(
                  onTap: () => _showHistoryDetail(context, {
                    'isWin': true,
                    'team': 'THIEF',
                    'scoreDelta': 45,
                    'date': '2024.05.18 12:00',
                    'result': '도둑 승리 (탈출 성공)',
                    'mode': 'ITEM',
                    'players': 8,
                    'duration': '20분 10초',
                    'arrests': 2,
                    'rescues': 3,
                  }),
                  child: HistoryCard(
                    isWin: true,
                    teamType: Team.thief,
                    scoreDelta: 45,
                    date: '2024.05.18 12:00',
                    resultText: '도둑 승리 (탈출 성공)',
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
              gradient: LinearGradient(colors: [neonCyan, neonPurple]),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 32,
            ),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statGrid(int totalGames, int wins, int losses, int totalPlaySec) {
    final winRate = totalGames > 0
        ? (wins / totalGames * 100).toStringAsFixed(1)
        : '0.0';

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _statCard('총 경기', '$totalGames게임'),
        _statCard('승률', '$winRate%'),
        _statCard('승/패', '$wins승 $losses패'),
        _statCard('플레이 시간', _formatDuration(totalPlaySec)),
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

  Widget _mannerCard(int mannerScore) {
    final progress = mannerScore / 100.0;
    return GlowCard(
      glow: true,
      glowColor: neonLime,
      borderColor: neonLime.withOpacity(0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${mannerScore}점',
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
                      item.unlocked
                          ? Icons.emoji_events_rounded
                          : Icons.lock_rounded,
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

  List<AchievementSummary> _mockAchievements() {
    return const [
      AchievementSummary(title: '첫 체포', unlocked: true),
      AchievementSummary(title: '첫 경기', unlocked: true),
      AchievementSummary(title: '3연승', unlocked: false),
      AchievementSummary(title: '구출 전문가', unlocked: false),
      AchievementSummary(title: '100km 달성', unlocked: false),
      AchievementSummary(title: '10경기 완주', unlocked: true),
    ];
  }

  void _showHistoryDetail(BuildContext context, Map<String, dynamic> data) {
    final isWin = data['isWin'] as bool;
    final team = data['team'] as String;
    final scoreDelta = data['scoreDelta'] as int;
    final date = data['date'] as String;
    final result = data['result'] as String;
    final mode = data['mode'] as String;
    final players = data['players'] as int;
    final duration = data['duration'] as String;
    final arrests = data['arrests'] as int;
    final rescues = data['rescues'] as int;

    final accentColor = team == 'POLICE' ? AppColors.borderCyan : AppColors.red;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: isWin ? accentColor.withOpacity(0.5) : AppColors.outlineLow,
          ),
          boxShadow: isWin
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  team == 'POLICE' ? Icons.shield_rounded : Icons.lock_rounded,
                  color: isWin ? accentColor : AppColors.textMuted,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (scoreDelta >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent)
                            .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (scoreDelta > 0 ? '+' : '') + scoreDelta.toString(),
                    style: TextStyle(
                      color: scoreDelta >= 0
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Details Grid
            _detailRow('게임 모드', mode == 'ITEM' ? '아이템전' : '일반전'),
            _detailRow('참여 인원', '$players명'),
            _detailRow('진행 시간', duration),
            _detailRow('체포', '$arrests회'),
            _detailRow('구출', '$rescues회'),
            _detailRow('일시', date),
            const SizedBox(height: 20),
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor.withOpacity(0.2),
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: accentColor.withOpacity(0.5)),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  '닫기',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
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
