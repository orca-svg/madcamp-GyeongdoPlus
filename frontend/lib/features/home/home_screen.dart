// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/connection_indicator.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/rank_neon_card.dart';
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
    final bottomInset = bottomPad + 18;

    // Use real user data from AuthProvider
    final user = auth.user;
    final displayName = user?.nickname ?? auth.displayName ?? '김선수';
    final policeScore = user?.policeScore ?? 0;
    final thiefScore = user?.thiefScore ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset),
            child: Column(
              children: [
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '환영합니다',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ✅ 이름 Row 우측에 워치 인디케이터 배치
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ConnectionIndicator(
                            icon: Icons.watch_rounded,
                            connected: watchConnected,
                            label: watchConnected ? '워치' : '오프',
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(
                        '시즌 12',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),

                      // ✅ 경찰/도둑 네온 랭크 카드 (cyan / red)
                      Row(
                        children: [
                          Expanded(
                            child: RankNeonCard(
                              title: '경찰',
                              score: policeScore,
                              icon: Icons.shield_rounded,
                              accent: AppColors.borderCyan,
                              rankName: _rankNameFromScore(
                                policeScore,
                                'POLICE',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RankNeonCard(
                              title: '도둑',
                              score: thiefScore,
                              icon: Icons.lock_rounded,
                              accent: AppColors.red,
                              rankName: _rankNameFromScore(thiefScore, 'THIEF'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ✅ 버튼 영역은 Expanded로 가운데 정렬 유지 (오버플로 방지)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GradientButton(
                        variant: GradientButtonVariant.createRoom,
                        title: '방 만들기',
                        height: 76,
                        borderRadius: 20,
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
                      const SizedBox(height: 18),
                      GradientButton(
                        variant: GradientButtonVariant.joinRoom,
                        title: '방 참여하기',
                        height: 76,
                        borderRadius: 20,
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

  String _rankNameFromScore(int score, String role) {
    final r = role.toUpperCase();

    // ✅ "내 정보 탭에서처럼" 역할별 랭크명 제공
    if (r == 'POLICE') {
      if (score >= 3000) return '특수요원';
      if (score >= 2000) return '강력반';
      if (score >= 1200) return '경사';
      if (score >= 600) return '순경';
      if (score > 0) return '훈련생';
      return 'Unranked';
    }

    // THIEF
    if (score >= 3000) return '전설의 도둑';
    if (score >= 2000) return '괴도';
    if (score >= 1200) return '전문털이범';
    if (score >= 600) return '소매치기';
    if (score > 0) return '연습생';
    return 'Unranked';
  }
}
