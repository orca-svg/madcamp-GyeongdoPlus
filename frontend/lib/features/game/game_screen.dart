import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/game_provider.dart';
import '../map/game_map_renderer.dart';
import '../ingame/widgets/game_rules_overlay.dart';
import 'providers/ability_provider.dart';
import 'providers/item_provider.dart';
import 'widgets/item_slot_hud.dart';
import 'widgets/ability_button.dart';
import '../../core/services/audio_service.dart'; // Audio

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _renderer = GameMapRenderer();
  Timer? _gameTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Start tracking location and connecting socket listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).startGame();

      // Play Game BGM
      ref.read(audioServiceProvider).playBgm(AudioType.bgmChase);

      // Initialize item system
      final rules = ref.read(matchRulesProvider);
      final room = ref.read(roomProvider);
      final myTeam = room.me?.team;
      if (myTeam != null) {
        ref
            .read(itemProvider.notifier)
            .initializeForGame(
              gameDurationSec: rules.timeLimitSec,
              myTeam: myTeam,
            );
      }

      // Start global timer
      _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed += const Duration(seconds: 1);
        });
      });
    });
  }

  @override
  void dispose() {
    // Stop tracking handled by provider if needed, or explicitly here
    // ref.read(gameProvider.notifier).stopGame();
    ref.read(itemProvider.notifier).stop();
    // Stop BGM
    ref.read(audioServiceProvider).stopBgm();
    _gameTimer?.cancel();
    super.dispose();
  }

  void _showRulesOverlay(MatchRulesState rules) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
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
    final gameState = ref.watch(gameProvider);
    final ability = ref.watch(abilityProvider);

    // 1. Build Static Map Elements
    List<GeoPointDto>? zonePolygon;
    GeoPointDto? jailCenter;
    double jailRadiusM = 12.0;

    if (room.mapConfig != null) {
      final polyRaw = room.mapConfig!['polygon'] as List?;
      if (polyRaw != null) {
        zonePolygon = polyRaw.map((e) => GeoPointDto.fromJson(e)).toList();
      }
      final jailRaw = room.mapConfig!['jail'] as Map<String, dynamic>?;
      if (jailRaw != null) {
        jailCenter = GeoPointDto(
          lat: (jailRaw['lat'] as num).toDouble(),
          lng: (jailRaw['lng'] as num).toDouble(),
        );
        jailRadiusM = (jailRaw['radiusM'] as num?)?.toDouble() ?? 12.0;
      }
    } else {
      zonePolygon = rules.zonePolygon;
      jailCenter = rules.jailCenter;
      jailRadiusM = rules.jailRadiusM ?? 12.0;
    }

    final polygons = _renderer.buildPolygons(zonePolygon);
    final circles = _renderer.buildCircles(jailCenter, jailRadiusM);

    // 2. Fog of War Logic
    final myTeam = room.me?.team;
    final myTeamStr = myTeam == Team.police ? 'POLICE' : 'THIEF';

    // Ability: Finder (active reveals enemies)
    final bool isFinderActive =
        ability.type == AbilityType.scanner && ability.isSkillActive;

    // Filter players
    final visiblePlayers = gameState.players.values.where((p) {
      // Hide self (separate marker)
      if (p.userId == room.myId) return false;

      final isTeammate = p.team == myTeamStr;

      // Teammate always visible
      if (isTeammate) return true;

      // Enemy visible if Finder active
      if (isFinderActive && !isTeammate) return true;

      if (isFinderActive && !isTeammate) return true;

      return false;
    }).toList();

    // Check if I am arrested
    final myPlayerState = gameState.players[room.myId];
    final bool amIArrested = myPlayerState?.isArrested ?? false;

    // Markers
    final List<Marker> markers = visiblePlayers.map((p) {
      final isTeammate = p.team == myTeamStr;

      // Determine marker image based on team
      // Police -> Blue, Thief -> Red
      // We use local assets. Note: KakaoMap plugin might require specific path format or URL.
      // Trying standard asset path first.
      final isPolice = p.team == 'POLICE';
      final imageSrc = isPolice
          ? 'assets/icon/marker_blue.png'
          : 'assets/icon/marker_red.png';

      return Marker(
        markerId: p.userId,
        latLng: LatLng(p.lat, p.lng),
        infoWindowContent: isTeammate ? '아군' : '적군 (탐지됨)',
        markerImageSrc: imageSrc,
        // MarkerImage(width: 24, height: 24, ...) if supported,
        // but plugin usuall only takes src string in constructor or separate param.
        // Checking plugin definition: Marker({required this.markerId, ..., this.markerImageSrc})
      );
    }).toList();

    // Self Marker
    final myPos = gameState.myPosition;
    if (myPos != null) {
      final amIPolice = myTeam == Team.police;
      final myImageSrc = amIPolice
          ? 'assets/icon/marker_blue.png'
          : 'assets/icon/marker_red.png';

      markers.add(
        Marker(
          markerId: 'self_marker',
          latLng: LatLng(myPos.latitude, myPos.longitude),
          infoWindowContent: '나',
          markerImageSrc: myImageSrc,
        ),
      );
    }

    // Map Center
    LatLng center;
    if (myPos != null) {
      center = LatLng(myPos.latitude, myPos.longitude);
    } else if (jailCenter != null) {
      center = LatLng(jailCenter.lat, jailCenter.lng);
    } else {
      center = LatLng(37.5665, 126.9780);
    }

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
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '게임 진행 중',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          _fmtDuration(_elapsed),
                          style: const TextStyle(
                            color: AppColors.borderCyan,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
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

                  // Map Area
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
                          child: KakaoMap(
                            key: ValueKey(
                              'game_map_${polygons.length}_${markers.length}_${center.latitude}_${center.longitude}',
                            ),
                            onMapCreated: (comp) {},
                            center: center,
                            currentLevel: 3,
                            zoomControl: true,
                            mapTypeControl: false,
                            polygons: polygons,
                            circles: circles,
                            markers: markers,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom panels
                ],
              ),

              // Item Slots (Bottom Left) - Only for ITEM Mode
              if (rules.gameMode == GameMode.item)
                const Positioned(bottom: 120, left: 20, child: ItemSlotHUD()),

              // Ability Button (Bottom Right)
              Positioned(
                bottom: 120,
                right: 20,
                child: AbilityButton(
                  ability: ability,
                  onPressed: () =>
                      ref.read(abilityProvider.notifier).useSkill(),
                ),
              ),

              // Red Vignette (Arrested)
              if (amIArrested)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.red.withOpacity(0.6),
                          ],
                          radius: 1.2,
                          // Vignette means corners are red.
                          // Actually RadialGradient center is center.
                          stops: const [0.4, 1.0],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '체 포 됨',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: AppColors.red.withOpacity(0.8),
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Debug Info
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: Text(
                    'Players: ${gameState.players.length} / Visible: ${markers.length}\n'
                    'Tracking: ${gameState.isTracking}\n'
                    'MyPos: ${myPos?.latitude.toStringAsFixed(4)}, ${myPos?.longitude.toStringAsFixed(4)}\n'
                    'Ability: ${ability.type.label} (${ability.isSkillActive
                        ? "Active"
                        : ability.isReady
                        ? "Ready"
                        : "${ability.cooldownRemainSec}s"})',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
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

String _fmtDuration(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
