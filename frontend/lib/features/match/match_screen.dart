import 'package:flutter/material.dart';
import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

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
                Text('경기 설정', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('방장만 세부 항목을 설정할 수 있습니다.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    Expanded(child: _SideCard(title: '경찰', value: '3', accent: AppColors.borderCyan, icon: Icons.shield_rounded)),
                    SizedBox(width: 14),
                    Expanded(child: _SideCard(title: '도둑', value: '2', accent: AppColors.red, icon: Icons.lock_rounded)),
                  ],
                ),
                const SizedBox(height: 22),
                Text('경기 규칙', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                const _RuleTile(title: '경기 시간', value: '10분', accent: AppColors.borderCyan),
                const SizedBox(height: 12),
                const _RuleTile(title: '경기장', value: '도심', accent: AppColors.borderCyan),
                const SizedBox(height: 12),
                const _RuleTile(title: '경기 참여 인원', value: '최대 5명', accent: AppColors.borderCyan),
                const SizedBox(height: 12),
                const _RuleTile(title: '해방 방식', value: '터치/근접', accent: AppColors.borderCyan),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  const _SideCard({required this.title, required this.value, required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: accent.withOpacity(0.10),
      borderColor: accent.withOpacity(0.35),
      child: SizedBox(
        height: 96,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Text(value, style: TextStyle(color: accent, fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;

  const _RuleTile({required this.title, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glow: false,
      borderColor: accent.withOpacity(0.25),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          ),
          Text(value, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
