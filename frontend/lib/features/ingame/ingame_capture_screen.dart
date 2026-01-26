import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/watch_provider.dart';

class InGameCaptureScreen extends ConsumerWidget {
  const InGameCaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchConnected = ref.watch(watchConnectedProvider);
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
                        '체포',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '거리: 10m (placeholder)',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        watchConnected ? '워치 연결됨' : '워치 연결 안됨',
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
                  variant: GradientButtonVariant.joinRoom,
                  title: '체포 시도(디버그)',
                  height: 54,
                  borderRadius: 16,
                  onPressed: () {},
                  leading: const Icon(
                    Icons.lock_rounded,
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
