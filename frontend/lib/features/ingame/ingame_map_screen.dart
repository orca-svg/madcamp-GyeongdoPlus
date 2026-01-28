import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/room_provider.dart';
import '../map/game_map_renderer.dart';
import 'widgets/game_rules_overlay.dart';

class InGameMapScreen extends ConsumerStatefulWidget {
  const InGameMapScreen({super.key});

  @override
  ConsumerState<InGameMapScreen> createState() => _InGameMapScreenState();
}

class _InGameMapScreenState extends ConsumerState<InGameMapScreen> {
  final _renderer = GameMapRenderer();
  KakaoMapController? _mapController; // Safe controller reference

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          bottom: false,
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
                                key: ValueKey(
                                  'ingame_map_${rules.zonePolygon?.length ?? 0}_${rules.jailCenter?.lat ?? 0}',
                                ),
                                onMapCreated: (controller) {
                                  if (!mounted) return;
                                  setState(() {
                                    _mapController = controller;
                                  });
                                },
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
                  const SizedBox(height: 20),
                ],
              ),

              // Auto-arrest system status indicator (debug)
              if (kDebugMode && isPolice)
                Positioned(
                  top: 80,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '자동 체포 시스템 활성화',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 12),
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
