import 'package:flutter/material.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/delta_chip.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, AppDimens.bottomBarHIn + 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('프로필', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('계정 및 설정', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 14),
                _topProfileCard(context),
                const SizedBox(height: 16),
                _statGrid(),
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

  Widget _topProfileCard(BuildContext context) {
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
                      child: const Text('42', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('김선수', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    SizedBox(height: 4),
                    Text('@pro_player_kim', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    SizedBox(height: 8),
                    _Badge(text: '다이아몬드 II', icon: Icons.stars_rounded, color: AppColors.purple),
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
                      const Text('#342', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      const Text('Global Rank', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 8),
                      const Align(alignment: Alignment.centerRight, child: DeltaChip(delta: 58.0)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.outlineLow, height: 1),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniMetric(value: '1,247', label: '총 게임'),
              _MiniMetric(value: '67.8%', label: '승률', valueColor: AppColors.borderCyan),
              _MiniMetric(value: '2.63', label: 'K/D', valueColor: AppColors.lime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.26,
      children: const [
        _StatCard(
          title: '승률',
          value: '67.8%',
          subtitle: 'Win Rate',
          accent: AppColors.lime,
          delta: 2.3,
          icon: Icons.emoji_events_rounded,
        ),
        _StatCard(
          title: '킬',
          value: '1,247',
          subtitle: 'Total Kills',
          accent: AppColors.borderCyan,
          delta: 156,
          icon: Icons.track_changes_rounded,
        ),
        _StatCard(
          title: '플레이 기간',
          value: '156일',
          subtitle: 'Play Days',
          accent: AppColors.lime,
          icon: Icons.calendar_month_rounded,
        ),
        _StatCard(
          title: '총 플레이',
          value: '342시간',
          subtitle: 'Play Time',
          accent: AppColors.purple,
          icon: Icons.timer_rounded,
        ),
      ],
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
                  style: TextStyle(
                    color: destructive ? AppColors.red : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
  final double? delta;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
    this.delta,
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
              if (delta != null) DeltaChip(delta: delta!),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

