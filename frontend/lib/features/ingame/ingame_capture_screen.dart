import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/app_providers.dart';
import '../../providers/game_provider.dart';
import '../../providers/room_provider.dart';

class InGameCaptureScreen extends ConsumerStatefulWidget {
  const InGameCaptureScreen({super.key});

  @override
  ConsumerState<InGameCaptureScreen> createState() =>
      _InGameCaptureScreenState();
}

class _InGameCaptureScreenState extends ConsumerState<InGameCaptureScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);
    final game = ref.watch(gameProvider);
    final me = room.me;
    final isPolice = me?.team == Team.police;

    final nearestEnemyDistance = _nearestEnemyDistance(game, room);
    final nearestText = nearestEnemyDistance == null
        ? '주변 적 위치 데이터가 없습니다.'
        : '가장 가까운 적까지 약 ${nearestEnemyDistance.round()}m';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPolice ? '자동 체포' : '자수',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPolice
                            ? '경찰 체포는 서버가 이동 위치를 기준으로 자동 판정합니다.'
                            : '도둑은 필요할 때 자수하여 즉시 체포 상태로 전환할 수 있습니다.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        nearestText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (isPolice)
                  GlowCard(
                    glow: false,
                    borderColor: AppColors.outlineLow,
                    child: Text(
                      '팁: 적과 1m 이내 근접 상태를 유지하면 서버의 `/game/move` 로직이 체포를 진행합니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                const Spacer(),
                GradientButton(
                  variant: GradientButtonVariant.joinRoom,
                  title: isPolice
                      ? '체포는 자동 판정됩니다'
                      : (_loading ? '자수 요청 중...' : '자수하기'),
                  height: 48,
                  borderRadius: 14,
                  onPressed: isPolice || _loading || !room.inRoom
                      ? null
                      : () => _surrender(context, room.roomId),
                  leading: Icon(
                    isPolice ? Icons.route_rounded : Icons.flag_rounded,
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

  double? _nearestEnemyDistance(GameState game, RoomState room) {
    final myPos = game.myPosition;
    if (myPos == null) return null;

    final myTeam = room.me?.team == Team.police ? 'POLICE' : 'THIEF';
    double? nearest;

    for (final player in game.players.values) {
      if (player.userId == room.myId) continue;
      if (player.team == myTeam) continue;

      final distance = Geolocator.distanceBetween(
        myPos.latitude,
        myPos.longitude,
        player.lat,
        player.lng,
      );
      if (nearest == null || distance < nearest) {
        nearest = distance;
      }
    }

    return nearest;
  }

  Future<void> _surrender(BuildContext context, String matchId) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(gameRepositoryProvider);
      final result = await repo.arrest(matchId);
      if (!context.mounted) return;

      if (result.success) {
        showAppSnackBar(context, message: '자수 요청을 전송했습니다.');
      } else {
        showAppSnackBar(
          context,
          message: result.errorMessage ?? '자수에 실패했습니다.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
