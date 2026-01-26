import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/room_provider.dart';

class InGameOverviewScreen extends ConsumerStatefulWidget {
  const InGameOverviewScreen({super.key});

  @override
  ConsumerState<InGameOverviewScreen> createState() =>
      _InGameOverviewScreenState();
}

class _InGameOverviewScreenState extends ConsumerState<InGameOverviewScreen> {
  Timer? _timer;
  int _remainSec = 600;
  int _policeScore = 0;
  int _thiefScore = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainSec <= 0) return;
      setState(() => _remainSec -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _fmtTime(_remainSec);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              children: [
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '타이머',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      Text(
                        timeText,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '점수',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _scoreCard(
                              label: '경찰',
                              value: _policeScore,
                              onAdd: () => setState(() => _policeScore += 1),
                              onSub: () => setState(() {
                                if (_policeScore > 0) _policeScore -= 1;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _scoreCard(
                              label: '도둑',
                              value: _thiefScore,
                              onAdd: () => setState(() => _thiefScore += 1),
                              onSub: () => setState(() {
                                if (_thiefScore > 0) _thiefScore -= 1;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GradientButton(
                  variant: GradientButtonVariant.createRoom,
                  title: '게임 종료(디버그)',
                  height: 54,
                  borderRadius: 16,
                  onPressed: () {
                    ref.read(roomProvider.notifier).leaveRoom();
                    ref.read(gamePhaseProvider.notifier).toOffGame();
                  },
                  leading: const Icon(
                    Icons.stop_circle_rounded,
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

Widget _scoreCard({
  required String label,
  required int value,
  required VoidCallback onAdd,
  required VoidCallback onSub,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface2.withOpacity(0.4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.outlineLow),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onSub,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
      ],
    ),
  );
}

String _fmtTime(int sec) {
  final m = (sec ~/ 60).toString().padLeft(2, '0');
  final s = (sec % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
