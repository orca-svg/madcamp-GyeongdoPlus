import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/room_provider.dart';

class IngameSettingsScreen extends ConsumerStatefulWidget {
  const IngameSettingsScreen({super.key});

  @override
  ConsumerState<IngameSettingsScreen> createState() =>
      _IngameSettingsScreenState();
}

class _IngameSettingsScreenState extends ConsumerState<IngameSettingsScreen> {
  bool _soundOn = true;
  bool _vibrationOn = true;
  bool _notifyOn = true;

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);
    final rules = ref.watch(matchRulesProvider);
    final isHost = room.amIHost;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              18,
              14,
              18,
              AppDimens.bottomBarHIn + 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('설정', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '사운드/진동/알림',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _soundOn,
                        onChanged: (v) => setState(() => _soundOn = v),
                        title: const Text('사운드'),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _vibrationOn,
                        onChanged: (v) => setState(() => _vibrationOn = v),
                        title: const Text('진동'),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _notifyOn,
                        onChanged: (v) => setState(() => _notifyOn = v),
                        title: const Text('알림'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '게임 시간',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          if (!isHost)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface2.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.outlineLow),
                              ),
                              child: const Text(
                                'READ ONLY',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${rules.timeLimitSec ~/ 60}분',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          const min = 300.0;
                          const max = 1800.0;
                          final span = (max - min).round();
                          final divisions =
                              span >= 1 ? ((max - min) / 60).round() : null;
                          final enabled = isHost && divisions != null;

                          return Slider(
                            min: min,
                            max: max,
                            divisions: divisions,
                            value: rules.timeLimitSec
                                .clamp(min.toInt(), max.toInt())
                                .toDouble(),
                            onChanged: enabled
                                ? (v) => ref
                                      .read(matchRulesProvider.notifier)
                                      .setTimeLimitSec(v.round())
                                : null,
                          );
                        },
                      ),
                      if (!isHost) ...[
                        const SizedBox(height: 4),
                        Text(
                          '시간은 방장만 변경할 수 있어요.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
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
