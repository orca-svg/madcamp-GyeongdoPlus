// In-game map: taller map area and server-driven polygon/jail display only.
// Why: give more space to the map without adding edit interactions.
// Keeps polygon/circle from matchRulesProvider and shows missing config hints.
// Adjusts height dynamically to avoid overflow on small screens.
// Maintains neon border and legend pills.
// Adds ArrestPanel (Police Only) and GameRulesOverlay trigger.
// Includes Mock Location Logic for validation.
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/room_provider.dart';
import 'widgets/arrest_panel.dart';
import 'widgets/game_rules_overlay.dart';

class InGameMapScreen extends ConsumerStatefulWidget {
  const InGameMapScreen({super.key});

  @override
  ConsumerState<InGameMapScreen> createState() => _InGameMapScreenState();
}

class _InGameMapScreenState extends ConsumerState<InGameMapScreen> {
  // Mock Location Data for Validation
  // Thief is fixed at Seoul City Hall
  final LatLng _thiefPos = LatLng(37.5665, 126.9780);
  late LatLng _myPos;

  @override
  void initState() {
    super.initState();
    // Start ~110m away
    _myPos = LatLng(37.5675, 126.9780);
  }

  /// Simple Haversine Distance (Meters)
  double _calcDistance(LatLng p1, LatLng p2) {
    const R = 6371000; // Earth radius in meters
    final dLat = _degToRad(p2.latitude - p1.latitude);
    final dLng = _degToRad(p2.longitude - p1.longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(p1.latitude)) *
            math.cos(_degToRad(p2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  void _showRulesOverlay(MatchRulesState rules) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Handled by overlay widget
      builder: (_) => GameRulesOverlay(
        rules: rules,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(matchRulesProvider);
    final room = ref.watch(roomProvider);

    // Check if I am Police (default to false if not found)
    final isPolice = room.me?.team == Team.police;

    final polygon = rules.zonePolygon ?? const <GeoPointDto>[];
    final jailCenter = rules.jailCenter;
    final jailRadiusM = rules.jailRadiusM ?? 12;

    final LatLng center = polygon.isNotEmpty
        ? LatLng(polygon.first.lat, polygon.first.lng)
        : (jailCenter != null
              ? LatLng(jailCenter.lat, jailCenter.lng)
              : LatLng(37.5665, 126.9780));

    final polygonOverlay = polygon.length >= 3
        ? Polygon(
            polygonId: 'arena',
            points: [for (final p in polygon) LatLng(p.lat, p.lng)],
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

    // Distance Calculation Logic
    final distanceToThief = _calcDistance(_myPos, _thiefPos);
    // Arrest enabled if distance < 3.0m
    final canArrest = distanceToThief < 3.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          bottom: false, // Let ArrestPanel sit at bottom
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '지도',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () => _showRulesOverlay(rules),
                          icon: const Icon(Icons.info_outline_rounded),
                          color: AppColors.textPrimary,
                          tooltip: '규칙 보기',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      child: GlowCard(
                        glow: false,
                        borderColor: AppColors.outlineLow,
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusCard,
                          ),
                          child: Stack(
                            children: [
                              KakaoMap(
                                center: center,
                                currentLevel: 4,
                                zoomControl: true,
                                mapTypeControl: false,
                                polygons: polygonOverlay == null
                                    ? null
                                    : [polygonOverlay],
                                circles: jailCircle == null
                                    ? null
                                    : [jailCircle],
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _LegendPill(
                                      title: '경기구역',
                                      color: AppColors.borderCyan,
                                    ),
                                    const SizedBox(height: 6),
                                    _LegendPill(
                                      title: '감옥',
                                      color: AppColors.purple,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Space for Arrest Panel / Debug Panel
                  SizedBox(height: isPolice ? 100 : 20),
                ],
              ),

              // Police Only: Arrest Panel
              if (isPolice)
                ArrestPanel(
                  isEnabled: canArrest,
                  distanceM: distanceToThief, // Pass distance for feedback
                  onArrest: () {
                    showAppSnackBar(context, message: '도둑 체포 시도!');
                    // TODO: Send socket event 'arrest'
                  },
                ),

              // Mock Debug Control (move self close to thief)
              if (kDebugMode)
                Positioned(
                  bottom: 120,
                  left: 20,
                  child: FloatingActionButton.extended(
                    heroTag: 'mockMove',
                    backgroundColor: Colors.orange,
                    onPressed: () {
                      setState(() {
                        // Toggle between far and close
                        if (distanceToThief > 50) {
                          _myPos = LatLng(37.56651, 126.9780); // ~1.1m
                        } else {
                          _myPos = LatLng(37.5675, 126.9780); // ~110m
                        }
                      });
                    },
                    label: Text(distanceToThief > 50 ? '도둑 근처로 이동' : '멀리 이동'),
                    icon: const Icon(Icons.directions_run),
                  ),
                ),
            ],
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
