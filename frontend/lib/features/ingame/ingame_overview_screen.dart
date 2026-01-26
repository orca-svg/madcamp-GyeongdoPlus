import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/match_rules_provider.dart';
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

  @override
  void initState() {
    super.initState();
    final rules = ref.read(matchRulesProvider);
    _remainSec = rules.timeLimitSec;
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
    final rules = ref.watch(matchRulesProvider);
    final room = ref.watch(roomProvider);
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
                        '남은 시간',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      _modeChip(rules.gameMode.label),
                      const SizedBox(width: 10),
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
                      Text('상태', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _statusTile(
                              label: '남은 도둑',
                              value: '${room.thiefCount}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statusTile(
                              label: '체포됨',
                              value: '${room.policeCount}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _statusTile(
                              label: '참가자',
                              value: '${room.members.length}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statusTile(
                              label: '준비됨',
                              value: '${room.members.where((m) => m.ready).length}',
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
                  title: '게임 종료(테스트)',
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

  Widget _modeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _statusTile({required String label, required String value}) {
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
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtTime(int sec) {
  final m = (sec ~/ 60).toString().padLeft(2, '0');
  final s = (sec % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
