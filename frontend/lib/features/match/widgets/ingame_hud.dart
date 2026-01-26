import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../providers/match_state_sim_provider.dart';

class IngameHud extends ConsumerWidget {
  const IngameHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(matchStateSimProvider);
    if (snap == null) return const SizedBox.shrink();

    final score = snap.live.score;
    final cap = snap.live.captureProgress;
    final rescue = snap.live.rescueProgress;

    final remainingMs =
        (snap.time.endsAtMs ?? snap.time.serverNowMs) - snap.time.serverNowMs;
    final remainingSec = (remainingMs / 1000).ceil().clamp(0, 24 * 3600);

    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _pill(
                text: '도둑 생존 ${score.thiefFree} / 체포 ${score.thiefCaptured}',
                border: AppColors.outlineLow,
                fill: AppColors.surface2.withOpacity(0.35),
                textColor: AppColors.textSecondary,
              ),
              const Spacer(),
              _pill(
                text: _fmtDuration(remainingSec),
                border: AppColors.borderCyan.withOpacity(0.50),
                fill: AppColors.borderCyan.withOpacity(0.10),
                textColor: AppColors.borderCyan,
              ),
            ],
          ),
          if (cap != null) ...[
            const SizedBox(height: 10),
            Text(
              '체포 게이지',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: cap.progress01.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: AppColors.surface2.withOpacity(0.35),
                valueColor: AlwaysStoppedAnimation<Color>(
                  cap.allOk ? AppColors.lime : AppColors.orange,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _gateChip('NEAR', cap.nearOk, AppColors.borderCyan),
                _gateChip('SPEED', cap.speedOk, AppColors.orange),
                _gateChip('TIME', cap.timeOk, AppColors.purple),
              ],
            ),
          ],
          if (rescue != null) ...[
            const SizedBox(height: 10),
            Text(
              '구출',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: rescue.progress01.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.surface2.withOpacity(0.35),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lime),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _gateChip(String label, bool ok, Color color) {
    final border = ok ? color.withOpacity(0.60) : AppColors.outlineLow;
    final fill = ok ? color.withOpacity(0.14) : AppColors.surface2.withOpacity(0.25);
    final text = ok ? color : AppColors.textMuted;
    return _pill(text: label, border: border, fill: fill, textColor: text);
  }

  Widget _pill({
    required String text,
    required Color border,
    required Color fill,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  String _fmtDuration(int sec) {
    final s = sec.clamp(0, 24 * 3600);
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

