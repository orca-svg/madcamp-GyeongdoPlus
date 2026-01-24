import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/section_title.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        Text('프로필', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('계정 및 설정', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 14),

        // Profile top card
        GlowCard(
          borderColor: AppColors.ally.withOpacity(0.55),
          glowColor: AppColors.ally.withOpacity(0.10),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [AppColors.ally, AppColors.purple]),
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.warn,
                            border: Border.all(color: AppColors.surface, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: const Text('42', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('김선수', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text('@pro_player_kim', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        SizedBox(height: 8),
                        _Badge(text: '다이아몬드 II', icon: Icons.stars_rounded, color: AppColors.purple),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlowCard(
                      padding: const EdgeInsets.all(12),
                      borderColor: AppColors.purple.withOpacity(0.55),
                      glowColor: AppColors.purple.withOpacity(0.10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('랭킹', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          SizedBox(height: 6),
                          Text('#342', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                          SizedBox(height: 2),
                          Text('Global Rank', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('+58', style: TextStyle(color: AppColors.safe, fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _MiniMetric(value: '1,247', label: '총 게임'),
                  _MiniMetric(value: '67.8%', label: '승률'),
                  _MiniMetric(value: '2.63', label: 'K/D'),
                ],
              )
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2x2 stat cards
        Row(
          children: [
            Expanded(child: _statCard(title: '승률', value: '67.8%', sub: '+2.3%', icon: Icons.emoji_events_rounded, glow: AppColors.safe)),
            const SizedBox(width: 12),
            Expanded(child: _statCard(title: '킬', value: '1,247', sub: 'Total Kills', icon: Icons.gps_fixed_rounded, glow: AppColors.ally)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard(title: '플레이 기간', value: '156일', sub: '', icon: Icons.calendar_month_rounded, glow: AppColors.safe)),
            const SizedBox(width: 12),
            Expanded(child: _statCard(title: '총 플레이', value: '342시간', sub: '', icon: Icons.timer_rounded, glow: AppColors.purple)),
          ],
        ),

        const SizedBox(height: 18),
        const SectionTitle(title: '설정'),
        const SizedBox(height: 10),

        _settingsTile(icon: Icons.notifications_rounded, title: '알림 설정', subtitle: '푸시 알림 관리', color: AppColors.ally),
        const SizedBox(height: 10),
        _settingsTile(icon: Icons.shield_rounded, title: '개인정보', subtitle: '보안 및 프라이버시', color: AppColors.safe),
        const SizedBox(height: 10),
        _settingsTile(icon: Icons.settings_rounded, title: '게임 설정', subtitle: '그래픽, 사운드, 조작', color: AppColors.ally),
        const SizedBox(height: 10),
        _settingsTile(icon: Icons.logout_rounded, title: '로그아웃', subtitle: '계정에서 로그아웃', color: AppColors.enemy),

        const SizedBox(height: 18),
        Center(
          child: Text('버전 0.1.0 © 2026 GyeongdoPlus',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        )
      ],
    );
  }

  Widget _statCard({required String title, required String value, required String sub, required IconData icon, required Color glow}) {
    return GlowCard(
      borderColor: glow.withOpacity(0.55),
      glowColor: glow.withOpacity(0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: glow, size: 22),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(sub, style: TextStyle(color: glow, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _settingsTile({required IconData icon, required String title, required String subtitle, required Color color}) {
    return GlowCard(
      borderColor: AppColors.border,
      glowColor: Colors.black.withOpacity(0.0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
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
  const _MiniMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
