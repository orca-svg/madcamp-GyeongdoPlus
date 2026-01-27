import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../providers/match_rules_provider.dart';

class MiniMapCard extends ConsumerWidget {
  const MiniMapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(matchRulesProvider);
    final points = rules.zonePolygon ?? [];
    final jailCenter = rules.jailCenter;
    final jailRadius = rules.jailRadiusM;

    // LatLng for center calculation or just first point
    LatLng center = points.isNotEmpty
        ? LatLng(points.first.lat, points.first.lng)
        : (jailCenter != null
              ? LatLng(jailCenter.lat, jailCenter.lng)
              : LatLng(37.5665, 126.9780)); // Seoul default

    // Calculate centroid if polygon exists
    if (points.isNotEmpty) {
      double sumLat = 0;
      double sumLng = 0;
      for (var p in points) {
        sumLat += p.lat;
        sumLng += p.lng;
      }
      center = LatLng(sumLat / points.length, sumLng / points.length);
    }

    // If jail exists but no polygon, center on jail
    if (points.isEmpty && jailCenter != null) {
      center = LatLng(jailCenter.lat, jailCenter.lng);
    }

    final polygon = points.length >= 3
        ? Polygon(
            polygonId: 'preview_poly',
            points: points.map((e) => LatLng(e.lat, e.lng)).toList(),
            strokeWidth: 2,
            strokeColor: AppColors.borderCyan,
            strokeOpacity: 0.8,
            fillColor: AppColors.borderCyan,
            fillOpacity: 0.1,
          )
        : null;

    final circle = (jailCenter != null && jailRadius != null)
        ? Circle(
            circleId: 'preview_jail',
            center: LatLng(jailCenter.lat, jailCenter.lng),
            radius: jailRadius,
            strokeWidth: 2,
            strokeColor: AppColors.purple,
            strokeOpacity: 0.8,
            fillColor: AppColors.purple,
            fillOpacity: 0.1,
          )
        : null;

    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            children: [
              IgnorePointer(
                child: KakaoMap(
                  center: center,
                  currentLevel: 5,
                  polygons: polygon != null ? [polygon] : null,
                  circles: circle != null ? [circle] : null,
                  zoomControl: false,
                  mapTypeControl: false,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'MAP PREVIEW',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
