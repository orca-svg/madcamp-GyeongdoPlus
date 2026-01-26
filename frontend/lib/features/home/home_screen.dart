import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/watch_provider.dart';
import '../room/room_create_screen.dart';
import '../room/room_join_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final watchConnected = ref.watch(watchConnectedProvider);
    final phase = ref.watch(gamePhaseProvider);
    final bottomPad = (phase == GamePhase.offGame)
        ? AppDimens.bottomBarHOff
        : AppDimens.bottomBarHIn;
    final rankItems = _stubRanks();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPad + 12),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GlowCard(
                      glow: false,
                      borderColor: AppColors.outlineLow,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '환영합니다',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            auth.displayName ?? '김선수',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '시즌 12 • 다이아몬드 II',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _rankTile(
                                  icon: Icons.shield_rounded,
                                  label: '경찰 랭크',
                                  value: rankItems[0].displayText,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _rankTile(
                                  icon: Icons.lock_rounded,
                                  label: '도둑 랭크',
                                  value: rankItems[1].displayText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: -8,
                      child: Transform.translate(
                        offset: const Offset(0, 8),
                        child: _watchIndicatorCompact(watchConnected),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GradientButton(
                        variant: GradientButtonVariant.createRoom,
                        title: '방 만들기',
                        height: 64,
                        borderRadius: 18,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RoomCreateScreen(),
                            ),
                          );
                        },
                        leading: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        variant: GradientButtonVariant.joinRoom,
                        title: '방 참여하기',
                        height: 64,
                        borderRadius: 18,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RoomJoinScreen(),
                            ),
                          );
                        },
                        leading: const Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _watchIndicatorCompact(bool connected) {
    final color = connected ? AppColors.lime : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.watch_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            connected ? 'Connected' : 'Off',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineLow.withOpacity(0.9)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.borderCyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_RankInfo> _stubRanks() {
    return const [
      _RankInfo(role: 'POLICE', score: 1240, tierCode: 'DIAMOND_2'),
      _RankInfo(role: 'THIEF', score: 980, tierCode: 'PLATINUM_4'),
    ];
  }
}

class _RankInfo {
  final String role;
  final int score;
  final String tierCode;
  final String? subtitle;

  const _RankInfo({
    required this.role,
    required this.score,
    required this.tierCode,
    this.subtitle,
  });

  String get displayText => '${_tierLabel(tierCode)} · $score';
}

String _tierLabel(String code) {
  switch (code) {
    case 'DIAMOND_2':
      return '다이아 II';
    case 'PLATINUM_4':
      return '플래티넘 IV';
    default:
      return '브론즈 V';
  }
}
