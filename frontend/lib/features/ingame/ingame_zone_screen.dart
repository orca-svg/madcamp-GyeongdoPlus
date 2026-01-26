import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/match_rules_provider.dart';
import '../zone/zone_points_detail_screen.dart';

class IngameZoneScreen extends ConsumerWidget {
  const IngameZoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(matchRulesProvider);
    final polygon = rules.zonePolygon ?? const <GeoPointDto>[];
    final jailCenter = rules.jailCenter;
    final jailRadiusM = rules.jailRadiusM ?? 12.0;

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
                Text('구역', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '게임 구역',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        polygon.isEmpty
                            ? '폴리곤: 미설정'
                            : '폴리곤: ${polygon.length}점',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (polygon.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        for (final (i, p) in polygon.take(5).indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${i + 1}. ${_fmtPoint(p)}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (polygon.length > 5)
                          Text(
                            '... (+${polygon.length - 5}점)',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ZonePointsDetailScreen(
                                  points: polygon,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.borderCyan,
                          ),
                          child: const Text('전체 보기'),
                        ),
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
                      Text(
                        '감옥',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rules.jailEnabled ? '감옥: 활성' : '감옥: 비활성',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '감옥 반경: ${jailRadiusM.toStringAsFixed(0)}m',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        jailCenter == null
                            ? '감옥 중심: 미설정'
                            : '감옥 중심: ${_fmtPoint(jailCenter)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GradientButton(
                        variant: GradientButtonVariant.joinRoom,
                        height: 44,
                        borderRadius: 14,
                        title: '감옥 위치 보기(준비중)',
                        onPressed: () async {
                          await showDialog<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.surface1,
                              title: const Text('지도 비활성화'),
                              content: const Text(
                                '이번 단계에서는 지도 렌더를 비활성화했습니다.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: const Text('확인'),
                                ),
                              ],
                            ),
                          );
                        },
                        leading: const Icon(
                          Icons.location_on_rounded,
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

  static String _fmtPoint(GeoPointDto p) =>
      '${p.lat.toStringAsFixed(4)}, ${p.lng.toStringAsFixed(4)}';
}

