import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

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
                glowColor: AppColors.borderCyan.withOpacity(0.18),
                borderColor: AppColors.borderCyan.withOpacity(0.45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('로비', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text('팀/설정 준비 단계', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    GradientButton(
                      variant: GradientButtonVariant.createRoom,
                      title: '경기 시작',
                      onPressed: () => ref.read(gamePhaseProvider.notifier).toInGame(),
                      leading: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      variant: GradientButtonVariant.joinRoom,
                      title: '나가기',
                      onPressed: () => ref.read(gamePhaseProvider.notifier).toOffGame(),
                      leading: const Icon(Icons.exit_to_app_rounded, color: Colors.white),
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

