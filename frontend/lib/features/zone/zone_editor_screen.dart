// Zone editor: fix polygon rendering when points are removed or preview-only.
// Why: polygon should appear only with 3+ confirmed points and disappear immediately otherwise.
// GPS Init: Centers map on user location if available.
// Instant Pin: Tap to add immediately with haptic feedback.
// Legacy "Confirm" logic removed.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/room_provider.dart';

class ZoneEditorScreen extends ConsumerStatefulWidget {
  const ZoneEditorScreen({super.key});

  @override
  ConsumerState<ZoneEditorScreen> createState() => _ZoneEditorScreenState();
}

enum _EditMode { polygonPoint, jailCenter }

const double _radiusStepM = 5.0;

class _ZoneEditorScreenState extends ConsumerState<ZoneEditorScreen> {
  late List<GeoPointDto> _pointsConfirmed;
  GeoPointDto? _jailCenter;
  double? _jailRadiusM;
  _EditMode _mode = _EditMode.polygonPoint;

  KakaoMapController? _mapController;
  bool _mapBuilt = false;
  String? _mapDiag;
  bool _mapDiagScheduled = false;
  Timer? _mapDiagTimer;
  bool _keyLogged = false;

  // Initial GPS Location
  LatLng? _initialPos;

  static const bool _mapRenderDisabledThisStage = false;
  static const double _defaultJailRadiusM = 15.0;

  @override
  void initState() {
    super.initState();
    final rules = ref.read(matchRulesProvider);
    _pointsConfirmed = List<GeoPointDto>.from(
      rules.zonePolygon ?? const <GeoPointDto>[],
    );
    _jailCenter = rules.jailCenter;
    _jailRadiusM = rules.jailRadiusM;

    _initGps(); // Fire and forget

    _keyLogged = true;
  }

  Future<void> _initGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Handle service disabled
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _initialPos = LatLng(pos.latitude, pos.longitude);
      });
      debugPrint('[ZoneEditor] GPS found: ${pos.latitude}, ${pos.longitude}');

      // If map is already ready, move camera
      if (_mapController != null) {
        debugPrint('[ZoneEditor] PanTo GPS location (late)');
        _mapController!.panTo(_initialPos!);
      }
    } catch (e) {
      debugPrint('[ZoneEditor] GPS init failed: $e');
    }
  }

  @override
  void dispose() {
    _mapDiagTimer?.cancel();
    super.dispose();
  }

  bool get _mapEnabled {
    const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
    if (isFlutterTest) return false;
    final kakaoJsAppKey =
        (dotenv.isInitialized ? dotenv.env['KAKAO_JS_APP_KEY'] : null)
            ?.trim() ??
        '';
    return kakaoJsAppKey.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final showMap = !_mapRenderDisabledThisStage && _mapEnabled;
    _scheduleMapDiag(showMap);

    // Debug bypass: skip host check when started directly via DEBUG_START_ZONE_EDITOR
    const debugZoneEditor = bool.fromEnvironment('DEBUG_START_ZONE_EDITOR');
    final room = ref.watch(roomProvider);
    if (!debugZoneEditor && room.inRoom && !room.amIHost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '구역 설정',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  pointCount: _pointsConfirmed.length,
                  jailRadiusM: _jailRadiusM,
                ),
                const SizedBox(height: 14),
                _ModeToggle(
                  mode: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                  enabled: showMap,
                ),
                const SizedBox(height: 12),
                if (showMap)
                  _buildMapCard(context, showMap: showMap)
                else
                  Stack(
                    children: [
                      _buildFallbackCard(context),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _DebugPill(
                          keyOk: (dotenv.isInitialized
                              ? (dotenv.env['KAKAO_JS_APP_KEY'] ?? '')
                                    .trim()
                                    .isNotEmpty
                              : false),
                          built: _mapBuilt,
                          showMap: showMap,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                _ControlsCard(
                  points: _pointsConfirmed,
                  jailCenter: _jailCenter,
                  jailRadiusM: _jailRadiusM,
                  onUndo: (_pointsConfirmed.isEmpty)
                      ? null
                      : () => setState(() {
                          if (_pointsConfirmed.isNotEmpty) {
                            _pointsConfirmed = _pointsConfirmed.sublist(
                              0,
                              _pointsConfirmed.length - 1,
                            );
                          }
                        }),
                  onClear: () => setState(() {
                    _pointsConfirmed = [];
                    _jailCenter = null;
                    _jailRadiusM = null;
                  }),
                  onRadiusDelta: (delta) {
                    final base = (_jailRadiusM ?? 50.0);
                    final next = (base + delta).clamp(1.0, 200.0).toDouble();
                    setState(() => _jailRadiusM = next);
                  },
                  onRadiusChanged: (value) {
                    setState(() => _jailRadiusM = value);
                  },
                  radiusEnabled: _jailCenter != null,
                  onAddPointFallback: showMap ? null : _addPointFallback,
                  onSetJailCenterFallback: showMap
                      ? null
                      : _setJailCenterFallback,
                ),
                const SizedBox(height: 14),
                GradientButton(
                  key: const Key('zoneSave'),
                  variant: GradientButtonVariant.createRoom,
                  title: '저장',
                  onPressed: _pointsConfirmed.length >= 3 ? _save : null,
                  leading: const Icon(Icons.save_rounded, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  '지도 탭: 즉시 추가 (햅틱 피드백)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard(BuildContext context, {required bool showMap}) {
    final confirmed = _pointsConfirmed
        .map((p) => LatLng(p.lat, p.lng))
        .toList(growable: false);

    // Polygon appears only when points >= 3
    final polygonOverlay = (_pointsConfirmed.length >= 3)
        ? Polygon(
            polygonId: 'edit_polygon',
            points: confirmed,
            strokeWidth: 2,
            strokeColor: AppColors.borderCyan,
            strokeOpacity: 0.9,
            fillColor: AppColors.borderCyan,
            fillOpacity: 0.14,
            zIndex: 1,
          )
        : null;

    final jailCircle = (_jailCenter != null && _jailRadiusM != null)
        ? Circle(
            circleId: 'jail_circle',
            center: LatLng(_jailCenter!.lat, _jailCenter!.lng),
            radius: _jailRadiusM,
            strokeWidth: 2,
            strokeColor: AppColors.purple,
            strokeOpacity: 0.9,
            fillColor: AppColors.purple,
            fillOpacity: 0.12,
            zIndex: 2,
          )
        : null;

    final markers = <Marker>[
      for (var i = 0; i < confirmed.length; i++)
        Marker(
          markerId: 'p_$i',
          latLng: confirmed[i],
          width: 20,
          height: 24,
          zIndex: 3,
        ),
      if (_jailCenter != null)
        Marker(
          markerId: 'jail',
          latLng: LatLng(_jailCenter!.lat, _jailCenter!.lng),
          width: 26,
          height: 30,
          zIndex: 4,
        ),
    ];

    // Determine initial center: User GPS -> Confirmed Center -> Seoul City Hall
    LatLng center;
    if (confirmed.isNotEmpty) {
      center = _centroid(confirmed);
    } else {
      center = _initialPos ?? LatLng(37.5665, 126.9780);
    }

    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        child: SizedBox(
          height: 280,
          child: Stack(
            children: [
              KakaoMap(
                center: center,
                currentLevel: 4,
                zoomControl: false,
                mapTypeControl: false,
                polygons: polygonOverlay == null ? null : [polygonOverlay],
                circles: jailCircle == null ? null : [jailCircle],
                markers: markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (mounted) {
                    setState(() {
                      _mapBuilt = true;
                      _mapDiag = 'onMapCreated OK';
                    });
                    // Move to GPS buffer if available
                    if (_initialPos != null && confirmed.isEmpty) {
                      debugPrint('[ZoneEditor] PanTo GPS location (init)');
                      controller.panTo(_initialPos!);
                    }
                  }
                },
                onMapTap: (latLng) {
                  final p = GeoPointDto(
                    lat: latLng.latitude,
                    lng: latLng.longitude,
                  ).clamp();

                  HapticFeedback.lightImpact();

                  if (_mode == _EditMode.polygonPoint) {
                    setState(() {
                      _pointsConfirmed = [..._pointsConfirmed, p];
                    });
                  } else {
                    setState(() {
                      _jailCenter = p;
                      _jailRadiusM ??= _defaultJailRadiusM;
                    });
                  }
                },
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _DebugPill(
                  keyOk: (dotenv.isInitialized
                      ? (dotenv.env['KAKAO_JS_APP_KEY'] ?? '').trim().isNotEmpty
                      : false),
                  built: _mapBuilt,
                  showMap: showMap,
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface2.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.outlineLow),
                  ),
                  child: Text(
                    _mode == _EditMode.polygonPoint
                        ? '터치: 핀 추가 (즉시)'
                        : '터치: 감옥 설정',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: IconButton(
                  tooltip: '내 위치로 이동',
                  onPressed: () async {
                    if (_initialPos != null) {
                      _mapController?.panTo(_initialPos!);
                    } else {
                      await _initGps(); // retry
                    }
                  },
                  icon: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.textPrimary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface2.withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.outlineLow),
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

  void _scheduleMapDiag(bool showMap) {
    if (!showMap) return;
    if (_mapBuilt) return;
    if (_mapDiagScheduled) return;
    _mapDiagScheduled = true;
    _mapDiag ??= 'Map loading...';
    _mapDiagTimer?.cancel();
    _mapDiagTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_mapBuilt) return;
      setState(() {
        _mapDiag =
            'Map not created yet. Check Kakao Web domain (localhost/127.0.0.1) & key.';
      });
    });
  }

  Widget _buildFallbackCard(BuildContext context) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 단계에서는 지도 렌더를 비활성화했습니다.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            "점 추가/감옥 중심은 아래 버튼으로 설정하세요.",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  LatLng _centroid(List<LatLng> points) {
    var lat = 0.0;
    var lng = 0.0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  void _addPointFallback() {
    final base = const GeoPointDto(lat: 37.5665, lng: 126.9780);
    final i = _pointsConfirmed.length;
    final p = GeoPointDto(
      lat: base.lat + (i * 0.0007),
      lng: base.lng + (i * 0.0009),
    ).clamp();
    setState(() {
      _pointsConfirmed = [..._pointsConfirmed, p];
    });
  }

  void _setJailCenterFallback() {
    final center = (_pointsConfirmed.isNotEmpty)
        ? _pointsConfirmed.first
        : const GeoPointDto(lat: 37.5665, lng: 126.9780);
    setState(() => _jailCenter = center.clamp());
  }

  void _save() {
    ref.read(matchRulesProvider.notifier).setZonePolygon(_pointsConfirmed);
    ref
        .read(matchRulesProvider.notifier)
        .setJail(center: _jailCenter, radiusM: _jailRadiusM);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _DebugPill extends StatelessWidget {
  final bool keyOk;
  final bool built;
  final bool showMap;

  const _DebugPill({
    required this.keyOk,
    required this.built,
    required this.showMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineLow),
      ),
      child: Text(
        'SHOW_MAP:${showMap ? 'YES' : 'NO'} KEY:${keyOk ? 'OK' : 'EMPTY'} MAP:${built ? 'YES' : 'NO'}',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int pointCount;
  final double? jailRadiusM;

  const _SummaryCard({required this.pointCount, required this.jailRadiusM});

  @override
  Widget build(BuildContext context) {
    final radiusText = (jailRadiusM == null)
        ? '미설정'
        : '${jailRadiusM!.round()}m';
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '폴리곤 점: $pointCount / 최소 3',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '감옥: $radiusText',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _EditMode mode;
  final ValueChanged<_EditMode> onChanged;
  final bool enabled;

  const _ModeToggle({
    required this.mode,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Wrap(
          spacing: 10,
          children: [
            _chip(
              selected: mode == _EditMode.polygonPoint,
              label: '점 추가',
              onTap: () => onChanged(_EditMode.polygonPoint),
            ),
            _chip(
              selected: mode == _EditMode.jailCenter,
              label: '감옥 중심',
              onTap: () => onChanged(_EditMode.jailCenter),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required bool selected,
    required String label,
    required VoidCallback onTap,
  }) {
    final color = selected ? AppColors.borderCyan : AppColors.outlineLow;
    final textColor = selected
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface2.withOpacity(selected ? 0.45 : 0.25),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(selected ? 0.6 : 0.9)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ControlsCard extends StatelessWidget {
  final List<GeoPointDto> points;
  final GeoPointDto? jailCenter;
  final double? jailRadiusM;
  final VoidCallback? onUndo;
  final VoidCallback onClear;
  final ValueChanged<double> onRadiusDelta;
  final ValueChanged<double> onRadiusChanged;
  final bool radiusEnabled;
  final VoidCallback? onAddPointFallback;
  final VoidCallback? onSetJailCenterFallback;

  const _ControlsCard({
    required this.points,
    required this.jailCenter,
    required this.jailRadiusM,
    required this.onUndo,
    required this.onClear,
    required this.onRadiusDelta,
    required this.onRadiusChanged,
    required this.radiusEnabled,
    required this.onAddPointFallback,
    required this.onSetJailCenterFallback,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '컨트롤',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${points.length}점',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('zoneUndo'),
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('되돌리기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('zoneClear'),
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('전체 초기화'),
                ),
              ),
            ],
          ),
          if (onAddPointFallback != null ||
              onSetJailCenterFallback != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('zoneAddPoint'),
                    onPressed: onAddPointFallback,
                    icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                    label: const Text('점 추가'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('zoneSetJailCenter'),
                    onPressed: onSetJailCenterFallback,
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('감옥 중심'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '감옥 반경',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: radiusEnabled
                    ? () => onRadiusDelta(-_radiusStepM)
                    : null,
                icon: const Icon(Icons.remove_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface1,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: jailRadiusM ?? 15.0,
                  min: 1.0,
                  max: 200.0,
                  divisions: 199,
                  label: '${(jailRadiusM ?? 15.0).round()}m',
                  onChanged: radiusEnabled ? onRadiusChanged : null,
                ),
              ),
              IconButton(
                onPressed: radiusEnabled
                    ? () => onRadiusDelta(_radiusStepM)
                    : null,
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface1,
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
