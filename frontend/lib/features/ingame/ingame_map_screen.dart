import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../providers/match_rules_provider.dart';

class InGameMapScreen extends ConsumerWidget {
  const InGameMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(matchRulesProvider);
    final polygon = rules.zonePolygon ?? const <GeoPointDto>[];
    final jailCenter = rules.jailCenter;
    final jailRadiusM = rules.jailRadiusM ?? 12;

    final LatLng center = polygon.isNotEmpty
        ? LatLng(polygon.first.lat, polygon.first.lng)
        : (jailCenter != null
            ? LatLng(jailCenter.lat, jailCenter.lng)
            : const LatLng(37.5665, 126.9780));

    final polygonOverlay = polygon.length >= 3
        ? Polygon(
            polygonId: 'arena',
            points: [
              for (final p in polygon) LatLng(p.lat, p.lng),
            ],
            strokeColor: AppColors.borderCyan.withOpacity(0.9),
            strokeWidth: 2,
            fillColor: AppColors.borderCyan.withOpacity(0.14),
          )
        : null;

    final jailCircle = jailCenter == null
        ? null
        : Circle(
            circleId: 'jail',
            center: LatLng(jailCenter.lat, jailCenter.lng),
            radius: jailRadiusM.toDouble(),
            strokeColor: AppColors.purple.withOpacity(0.9),
            strokeWidth: 2,
            fillColor: AppColors.purple.withOpacity(0.14),
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, AppDimens.bottomBarHIn + 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('지도', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                    child: SizedBox(
                      height: 360,
                      child: Stack(
                        children: [
                          KakaoMap(
                            center: center,
                            currentLevel: 4,
                            zoomControl: true,
                            mapTypeControl: false,
                            polygons: polygonOverlay == null ? null : [polygonOverlay],
                            circles: jailCircle == null ? null : [jailCircle],
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: _LegendPill(
                              title: '경기구역',
                              color: AppColors.borderCyan,
                            ),
                          ),
                          Positioned(
                            top: 46,
                            right: 10,
                            child: _LegendPill(
                              title: '감옥',
                              color: AppColors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (polygon.isEmpty)
                  Text(
                    '구역 폴리곤이 설정되지 않았습니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                if (jailCenter == null)
                  Text(
                    '감옥 중심이 설정되지 않았습니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final String title;
  final Color color;

  const _LegendPill({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.55)),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
