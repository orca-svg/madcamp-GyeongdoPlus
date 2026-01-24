import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/shell_tab_request_provider.dart';

class PostGameScreen extends ConsumerWidget {
  const PostGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GlowCard(
                glowColor: AppColors.purple.withOpacity(0.18),
                borderColor: AppColors.purple.withOpacity(0.45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('경기 종료', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text('결과를 확인하세요', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    GradientButton(
                      variant: GradientButtonVariant.createRoom,
                      title: '전적 보기',
                      onPressed: () {
                        ref.read(shellTabRequestProvider.notifier).requestOffGameTab(1);
                        ref.read(gamePhaseProvider.notifier).toOffGame();
                      },
                      leading: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      variant: GradientButtonVariant.joinRoom,
                      title: '다시 로비',
                      onPressed: () => ref.read(gamePhaseProvider.notifier).toLobby(),
                      leading: const Icon(Icons.replay_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
