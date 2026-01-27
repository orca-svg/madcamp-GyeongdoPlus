import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/room_provider.dart';
import '../../services/watch_sync_service.dart';
import '../map/game_map_renderer.dart';
import 'widgets/arrest_panel.dart';
import 'widgets/game_rules_overlay.dart';

class InGameMapScreen extends ConsumerStatefulWidget {
  const InGameMapScreen({super.key});

  @override
  ConsumerState<InGameMapScreen> createState() => _InGameMapScreenState();
}

class _InGameMapScreenState extends ConsumerState<InGameMapScreen> {
  // Mock Location Data for Validation
  final LatLng _thiefPos = LatLng(37.5665, 126.9780);
  late LatLng _myPos;

  final _renderer = GameMapRenderer();

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

    // Build map overlays using renderer
    final polygons = _renderer.buildPolygons(rules.zonePolygon);
    final circles = _renderer.buildCircles(
      rules.jailCenter,
      rules.jailRadiusM ?? 12.0,
    );

    final center = polygons.isNotEmpty && polygons[0].points.isNotEmpty
        ? polygons[0].points[0]
        : (rules.jailCenter != null
              ? LatLng(rules.jailCenter!.lat, rules.jailCenter!.lng)
              : LatLng(37.5665, 126.9780));

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
                                polygons: polygons,
                                circles: circles,
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
                  onArrest: () async {
                    // Check Watch Connection
                    final sync = ref.read(watchSyncServiceProvider);
                    if (await sync.isPairedOrConnected()) {
                      await sync.sendHapticCommand({'kind': 'HEAVY'});
                      if (context.mounted) {
                        showAppSnackBar(context, message: '워치로 체포 진동 전송!');
                      }
                    } else {
                      HapticFeedback.heavyImpact();
                      if (context.mounted) {
                        showAppSnackBar(context, message: '도둑 체포 시도! (폰 진동)');
                      }
                    }
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
