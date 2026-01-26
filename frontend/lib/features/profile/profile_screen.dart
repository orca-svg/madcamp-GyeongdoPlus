import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/delta_chip.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../features/history/record_model.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/records_provider.dart';
import '../../providers/room_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider);
    final stats = _ProfileStats.fromRecords(records);
    final room = ref.watch(roomProvider);
    final nickname = room.me?.name ?? '김선수';
    final phase = ref.watch(gamePhaseProvider);
    final bottomPad = (phase == GamePhase.offGame) ? AppDimens.bottomBarHOff : AppDimens.bottomBarHIn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPad + 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('프로필', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('계정 및 설정', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 14),
                _topProfileCard(context, nickname: nickname, stats: stats),
                const SizedBox(height: 16),
                Text('랭크', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _rankRow(),
                const SizedBox(height: 16),
                Text('스탯', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _statGrid(stats),
                const SizedBox(height: 20),
                Text('업적', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _achievementGrid(context, _dummyAchievements(stats)),
                const SizedBox(height: 20),
                Text('매너', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _mannerCard(context),
                const SizedBox(height: 20),
                Text('설정', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _settingsTile(
                  icon: Icons.notifications_active_rounded,
                  title: '알림 설정',
                  subtitle: '푸시 알림 관리',
                  accent: AppColors.borderCyan,
                ),
                const SizedBox(height: 10),
                _settingsTile(
                  icon: Icons.shield_rounded,
                  title: '개인정보',
                  subtitle: '보안 및 프라이버시',
                  accent: AppColors.lime,
                ),
                const SizedBox(height: 10),
                _settingsTile(
                  icon: Icons.settings_rounded,
                  title: '게임 설정',
                  subtitle: '그래픽, 사운드, 조작',
                  accent: AppColors.borderCyan,
                ),
                const SizedBox(height: 10),
                _settingsTile(
                  icon: Icons.logout_rounded,
                  title: '로그아웃',
                  subtitle: '계정에서 로그아웃',
                  accent: AppColors.red,
                  destructive: true,
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    '버전 0.1.0 © 2026 GyeongdoPlus',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topProfileCard(
    BuildContext context, {
    required String nickname,
    required _ProfileStats stats,
  }) {
    final totalMatches = stats.policeMatches + stats.thiefMatches;
    return GlowCard(
      glowColor: AppColors.borderCyan.withOpacity(0.16),
      borderColor: AppColors.borderCyan.withOpacity(0.55),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppColors.borderCyan, AppColors.purple]),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 36),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange,
                        border: Border.all(color: AppColors.surface1, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$totalMatches',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '오늘도 안전하게!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    _Badge(
                      text: totalMatches == 0 ? '첫 게임을 준비 중' : '오프라인 전적 기반',
                      icon: Icons.stars_rounded,
                      color: AppColors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlowCard(
                  padding: const EdgeInsets.all(12),
                  glowColor: AppColors.purple.withOpacity(0.12),
                  borderColor: AppColors.purple.withOpacity(0.40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('랭킹', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 6),
                      const Text(
                        '#342',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Global Rank',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: DeltaChip(delta: stats.totalRatingDelta.toDouble()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.outlineLow, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniMetric(value: '$totalMatches', label: '총 경기'),
              _MiniMetric(value: '${stats.policeMatches}', label: '경찰 경기', valueColor: AppColors.borderCyan),
              _MiniMetric(value: '${stats.thiefMatches}', label: '도둑 경기', valueColor: AppColors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rankRow() {
    const policeLevel = 3;
    const policeProgress = 0.42;
    const thiefLevel = 2;
    const thiefProgress = 0.18;

    final policeRanks = const [
      '순경',
      '경장',
      '경사',
      '경위',
      '경감',
      '경정',
      '총경',
      '경무관',
      '치안감',
    ];
    final thiefRanks = const [
      '좀도둑',
      '소매치기',
      '전문털이범',
      '금고털이',
      '사기꾼',
      '조직원',
      '행동대장',
      '보스',
      '전설의 도둑',
    ];

    final policeRankName = policeRanks[(policeLevel - 1).clamp(0, policeRanks.length - 1)];
    final thiefRankName = thiefRanks[(thiefLevel - 1).clamp(0, thiefRanks.length - 1)];

    return Row(
      children: [
        Expanded(
          child: _rankCard(
            icon: Icons.shield_rounded,
            accent: AppColors.borderCyan,
            rankName: policeRankName,
            level: policeLevel,
            progress: policeProgress,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _rankCard(
            icon: Icons.lock_rounded,
            accent: AppColors.red,
            rankName: thiefRankName,
            level: thiefLevel,
            progress: thiefProgress,
          ),
        ),
      ],
    );
  }

  Widget _rankCard({
    required IconData icon,
    required Color accent,
    required String rankName,
    required int level,
    required double progress,
  }) {
    return GlowCard(
      glowColor: accent.withOpacity(0.12),
      borderColor: accent.withOpacity(0.35),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.25)),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rankName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.surface2.withOpacity(0.35),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Lv.$level',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statGrid(_ProfileStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.26,
      children: [
        _StatCard(
          title: '평균 체포 수',
          value: '${stats.avgCaught.toStringAsFixed(1)}명',
          subtitle: 'Police Avg Captures',
          accent: AppColors.borderCyan,
          icon: Icons.gavel_rounded,
        ),
        _StatCard(
          title: '평균 해방 수',
          value: '${stats.avgRescued.toStringAsFixed(1)}명',
          subtitle: 'Thief Avg Rescues',
          accent: AppColors.red,
          icon: Icons.handshake_rounded,
        ),
        _StatCard(
          title: '총 이동거리',
          value: formatKm(stats.totalDistanceM),
          subtitle: 'Total Distance',
          accent: AppColors.lime,
          icon: Icons.directions_run_rounded,
        ),
        _StatCard(
          title: '총 플레이 시간',
          value: formatDurationHhMm(stats.totalPlaySec),
          subtitle: 'Total Play Time',
          accent: AppColors.purple,
          icon: Icons.timer_rounded,
        ),
      ],
    );
  }

  Widget _achievementGrid(BuildContext context, List<_Achievement> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.20,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final a = items[i];
        final accent = a.unlocked ? a.accent : AppColors.outlineLow;
        return InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          onTap: () {
            showAppSnackBar(context, message: '다음 단계에서 업적 상세를 제공합니다');
          },
          child: GlowCard(
            glow: a.unlocked,
            glowColor: accent.withOpacity(0.12),
            borderColor: accent.withOpacity(a.unlocked ? 0.40 : 0.85),
            child: Opacity(
              opacity: a.unlocked ? 1.0 : 0.65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accent.withOpacity(0.22)),
                        ),
                        child: Icon(
                          a.unlocked ? a.icon : Icons.lock_rounded,
                          color: a.unlocked ? accent : AppColors.textMuted,
                          size: 18,
                        ),
                      ),
                      const Spacer(),
                      if (a.unlocked)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.lime,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _mannerCard(BuildContext context) {
    const score = 80;
    const warnings = 1;
    final v = (score / 100).clamp(0.0, 1.0);

    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lime.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lime.withOpacity(0.22)),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.lime,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '청렴도',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 10,
                    backgroundColor: AppColors.surface2.withOpacity(0.35),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.lime),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '경고 $warnings회',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$score',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    bool destructive = false,
  }) {
    return GlowCard(
      glow: false,
      borderColor: destructive ? AppColors.red.withOpacity(0.35) : AppColors.outlineLow,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withOpacity(0.25)),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: destructive ? AppColors.red : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _Badge({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _MiniMetric({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: accent.withOpacity(0.10),
      borderColor: accent.withOpacity(0.30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withOpacity(0.22)),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats {
  final int policeMatches;
  final int thiefMatches;
  final double avgCaught;
  final double avgRescued;
  final int totalDistanceM;
  final int totalPlaySec;
  final int totalRatingDelta;

  const _ProfileStats({
    required this.policeMatches,
    required this.thiefMatches,
    required this.avgCaught,
    required this.avgRescued,
    required this.totalDistanceM,
    required this.totalPlaySec,
    required this.totalRatingDelta,
  });

  factory _ProfileStats.fromRecords(List<RecordSummary> records) {
    int policeMatches = 0;
    int thiefMatches = 0;
    int policeCapSum = 0;
    int thiefRescueSum = 0;
    int totalDistanceM = 0;
    int totalPlaySec = 0;
    int totalRatingDelta = 0;

    for (final r in records) {
      final team = r.myTeam.toUpperCase();
      if (team == 'POLICE') {
        policeMatches += 1;
        policeCapSum += r.capturesOrRescues;
      } else if (team == 'THIEF') {
        thiefMatches += 1;
        thiefRescueSum += r.capturesOrRescues;
      }

      totalDistanceM += r.distanceM;
      totalPlaySec += r.durationSec;
      totalRatingDelta += r.ratingDelta;
    }

    return _ProfileStats(
      policeMatches: policeMatches,
      thiefMatches: thiefMatches,
      avgCaught: safeAvg(policeCapSum, policeMatches),
      avgRescued: safeAvg(thiefRescueSum, thiefMatches),
      totalDistanceM: totalDistanceM,
      totalPlaySec: totalPlaySec,
      totalRatingDelta: totalRatingDelta,
    );
  }
}

class _Achievement {
  final String title;
  final String subtitle;
  final bool unlocked;
  final IconData icon;
  final Color accent;

  const _Achievement({
    required this.title,
    required this.subtitle,
    required this.unlocked,
    required this.icon,
    required this.accent,
  });
}

List<_Achievement> _dummyAchievements(_ProfileStats stats) {
  final hasAny = (stats.policeMatches + stats.thiefMatches) > 0;
  final km = stats.totalDistanceM / 1000.0;

  return [
    _Achievement(
      title: '첫 경기',
      subtitle: '첫 경기를 완료하세요',
      unlocked: hasAny,
      icon: Icons.flag_rounded,
      accent: AppColors.borderCyan,
    ),
    _Achievement(
      title: '첫 체포',
      subtitle: '경찰로 체포를 1회 달성하세요',
      unlocked: stats.policeMatches > 0 && stats.avgCaught >= 1.0,
      icon: Icons.gavel_rounded,
      accent: AppColors.lime,
    ),
    _Achievement(
      title: '구출 전문가',
      subtitle: '도둑으로 구출을 3회 달성하세요',
      unlocked: stats.thiefMatches > 0 && stats.avgRescued >= 3.0,
      icon: Icons.handshake_rounded,
      accent: AppColors.orange,
    ),
    _Achievement(
      title: '10경기 완주',
      subtitle: '총 10경기를 완료하세요',
      unlocked: (stats.policeMatches + stats.thiefMatches) >= 10,
      icon: Icons.emoji_events_rounded,
      accent: AppColors.purple,
    ),
    _Achievement(
      title: '100km 달성',
      subtitle: '총 이동거리 100km 달성',
      unlocked: km >= 100.0,
      icon: Icons.directions_run_rounded,
      accent: AppColors.lime,
    ),
    _Achievement(
      title: '연승 도전',
      subtitle: '3연승을 달성하세요(다음 단계에서 집계)',
      unlocked: false,
      icon: Icons.bolt_rounded,
      accent: AppColors.borderCyan,
    ),
    _Achievement(
      title: '매너 플레이어',
      subtitle: '청렴도 90점 달성(다음 단계에서 집계)',
      unlocked: false,
      icon: Icons.verified_user_rounded,
      accent: AppColors.lime,
    ),
    _Achievement(
      title: '전설의 시작',
      subtitle: '전설의 도둑 랭크 달성(장기 목표)',
      unlocked: false,
      icon: Icons.auto_awesome_rounded,
      accent: AppColors.purple,
    ),
  ];
}

double safeAvg(int sum, int n) => (n == 0) ? 0.0 : (sum / n);

String formatKm(int meters) => '${(meters / 1000).toStringAsFixed(1)} km';

String formatDurationHhMm(int sec) {
  final s = sec.clamp(0, 24 * 3600 * 365);
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  if (h <= 0) return '$m분';
  return '$h시간 $m분';
}
