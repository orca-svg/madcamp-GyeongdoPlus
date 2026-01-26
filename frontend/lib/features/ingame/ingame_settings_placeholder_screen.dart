import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/room_provider.dart';

class InGameSettingsPlaceholderScreen extends ConsumerWidget {
  const InGameSettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              children: [
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '설정',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '게임 설정은 다음 단계에서 연결됩니다.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GradientButton(
                  variant: GradientButtonVariant.createRoom,
                  title: '게임 나가기',
                  height: 54,
                  borderRadius: 16,
                  onPressed: () {
                    ref.read(roomProvider.notifier).leaveRoom();
                    ref.read(gamePhaseProvider.notifier).toOffGame();
                  },
                  leading: const Icon(
                    Icons.exit_to_app_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
