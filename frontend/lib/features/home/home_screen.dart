import 'package:flutter/material.dart';
import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/delta_chip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                GlowCard(
                  glowColor: AppColors.purple.withOpacity(0.35),
                  borderColor: AppColors.borderCyan.withOpacity(0.55),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('환영합니다', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.titleLarge,
                          children: const [
                            TextSpan(text: '김선수'),
                            TextSpan(text: ' 님', style: TextStyle(color: AppColors.borderCyan)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('시즌 12 • 다이아몬드 II', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  variant: GradientButtonVariant.createRoom,
                  title: '방 만들기',
                  onPressed: () {},
                  leading: const Icon(Icons.add_rounded, color: Colors.white),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  variant: GradientButtonVariant.joinRoom,
                  title: '방 참여하기',
                  onPressed: () {},
                  leading: const Icon(Icons.login_rounded, color: Colors.white),
                ),
                const SizedBox(height: 26),
                Text('최근 활동', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _activityCard(
                  title: '승리!',
                  subtitle: '랭크 매치 • 2분 전',
                  delta: 25,
                  detail: 'K/D/A: 12/3/8',
                ),
                const SizedBox(height: 12),
                _activityCard(
                  title: '승리!',
                  subtitle: '랭크 매치 • 2일 전',
                  delta: 25,
                  detail: 'K/D/A: 12/3/8',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _activityCard({
    required String title,
    required String subtitle,
    required int delta,
    required String detail,
  }) {
    return GlowCard(
      glowColor: AppColors.borderCyan.withOpacity(0.12),
      borderColor: AppColors.borderCyan.withOpacity(0.55),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.borderCyan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderCyan.withOpacity(0.25)),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: AppColors.lime),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DeltaChip(delta: delta.toDouble(), suffix: ' LP'),
              const SizedBox(height: 8),
              Text(detail, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
