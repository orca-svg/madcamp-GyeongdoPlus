import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/room_provider.dart';

class InGameSettingsPlaceholderScreen extends ConsumerWidget {
  const InGameSettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(matchRulesProvider);
    final room = ref.watch(roomProvider);
    final isHost = room.amIHost;
    final min = 300.0;
    final max = 1800.0;
    final span = (max - min).round();
    final divisions = span >= 1 ? span : null;

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
                        '게임 시간',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${(rules.timeLimitSec / 60).round()}분 (${rules.timeLimitSec}s)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          if (!isHost)
                            Text(
                              '방장만 변경',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                        ],
                      ),
                      Slider(
                        min: min,
                        max: max,
                        divisions: divisions,
                        value: rules.timeLimitSec
                            .clamp(min.toInt(), max.toInt())
                            .toDouble(),
                        onChanged: isHost
                            ? (v) => ref
                                .read(matchRulesProvider.notifier)
                                .setTimeLimitSec(v.round())
                            : null,
                      ),
                      if (!isHost)
                        Text(
                          '시간 조절은 방장만 가능합니다.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textMuted),
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
