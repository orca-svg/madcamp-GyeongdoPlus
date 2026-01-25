import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  late List<GeoPointDto> _points;
  GeoPointDto? _jailCenter;
  double? _jailRadiusM;
  _EditMode _mode = _EditMode.polygonPoint;

  @override
  void initState() {
    super.initState();
    final rules = ref.read(matchRulesProvider);
    _points = List<GeoPointDto>.from(rules.zonePolygon ?? const <GeoPointDto>[]);
    _jailCenter = rules.jailCenter;
    _jailRadiusM = rules.jailRadiusM;
  }

  bool get _mapEnabled {
    const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
    if (isFlutterTest) return false;
    final kakaoJsAppKey = (dotenv.isInitialized ? dotenv.env['KAKAO_JS_APP_KEY'] : null)?.trim() ?? '';
    return kakaoJsAppKey.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);
    if (!room.amIHost) {
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
                    Text('구역 설정', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  pointCount: _points.length,
                  jailRadiusM: _jailRadiusM,
                ),
                const SizedBox(height: 14),
                _ModeToggle(
                  mode: _mode,
                  onChanged: (m) => setState(() => _mode = m),
                  enabled: _mapEnabled,
                ),
                const SizedBox(height: 12),
                _mapEnabled ? _buildMapCard(context) : _buildFallbackCard(context),
                const SizedBox(height: 14),
                _ControlsCard(
                  points: _points,
                  jailCenter: _jailCenter,
                  jailRadiusM: _jailRadiusM,
                  onUndo: _points.isEmpty ? null : () => setState(() => _points = _points.sublist(0, _points.length - 1)),
                  onClear: () => setState(() {
                    _points = [];
                    _jailCenter = null;
                    _jailRadiusM = null;
                  }),
                  onRadiusDelta: (delta) {
                    final base = (_jailRadiusM ?? 50.0);
                    final next = (base + delta).clamp(1.0, 200.0).toDouble();
                    setState(() => _jailRadiusM = next);
                  },
                  onAddPointFallback: _mapEnabled ? null : _addPointFallback,
                  onSetJailCenterFallback: _mapEnabled ? null : _setJailCenterFallback,
                ),
                const SizedBox(height: 14),
                GradientButton(
                  key: const Key('zoneSave'),
                  variant: GradientButtonVariant.createRoom,
                  title: '저장',
                  onPressed: _points.length >= 3 ? _save : null,
                  leading: const Icon(Icons.save_rounded, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  'TODO: zone_update / rules_update 스키마 확정 후 WS로 전송',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    final points = _points.map((p) => LatLng(p.lat, p.lng)).toList(growable: false);
    final center = _previewCenter(points, _jailCenter);

    final polygonOverlay = (_points.length >= 3)
        ? Polygon(
            polygonId: 'edit_polygon',
            points: points,
            strokeWidth: 3,
            strokeColor: AppColors.borderCyan,
            strokeOpacity: 0.9,
            fillColor: AppColors.borderCyan,
            fillOpacity: 0.10,
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
      for (var i = 0; i < points.length; i++)
        Marker(
          markerId: 'p_$i',
          latLng: points[i],
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
                onMapTap: (latLng) {
                  final p = GeoPointDto(lat: latLng.latitude, lng: latLng.longitude).clamp();
                  if (_mode == _EditMode.polygonPoint) {
                    setState(() => _points = [..._points, p]);
                  } else {
                    setState(() => _jailCenter = p);
                  }
                },
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface2.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.outlineLow),
                  ),
                  child: Text(
                    _mode == _EditMode.polygonPoint ? '탭: 점 추가' : '탭: 감옥 중심',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCard(BuildContext context) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KAKAO_JS_APP_KEY가 설정되지 않아 지도를 표시할 수 없습니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'frontend/.env에 키를 넣으면 지도에서 편집할 수 있습니다.\n'
            '지금은 아래 버튼으로 점을 추가/삭제할 수 있습니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  LatLng _previewCenter(List<LatLng> points, GeoPointDto? jailCenter) {
    if (jailCenter != null) return LatLng(jailCenter.lat, jailCenter.lng);
    if (points.isNotEmpty) return _centroid(points);
    return LatLng(37.5665, 126.9780);
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
    final i = _points.length;
    final p = GeoPointDto(lat: base.lat + (i * 0.0007), lng: base.lng + (i * 0.0009)).clamp();
    setState(() => _points = [..._points, p]);
  }

  void _setJailCenterFallback() {
    final center = (_points.isNotEmpty) ? _points.first : const GeoPointDto(lat: 37.5665, lng: 126.9780);
    setState(() => _jailCenter = center.clamp());
  }

  void _save() {
    ref.read(matchRulesProvider.notifier).setZonePolygon(_points);
    ref.read(matchRulesProvider.notifier).setJail(center: _jailCenter, radiusM: _jailRadiusM);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _SummaryCard extends StatelessWidget {
  final int pointCount;
  final double? jailRadiusM;

  const _SummaryCard({required this.pointCount, required this.jailRadiusM});

  @override
  Widget build(BuildContext context) {
    final radiusText = (jailRadiusM == null) ? '미설정' : '${jailRadiusM!.round()}m';
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '폴리곤 점: $pointCount / 최소 3',
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '감옥: $radiusText',
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800),
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

  const _ModeToggle({required this.mode, required this.onChanged, required this.enabled});

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

  Widget _chip({required bool selected, required String label, required VoidCallback onTap}) {
    final color = selected ? AppColors.borderCyan : AppColors.outlineLow;
    final textColor = selected ? AppColors.textPrimary : AppColors.textSecondary;
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
        child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 12)),
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
  final VoidCallback? onAddPointFallback;
  final VoidCallback? onSetJailCenterFallback;

  const _ControlsCard({
    required this.points,
    required this.jailCenter,
    required this.jailRadiusM,
    required this.onUndo,
    required this.onClear,
    required this.onRadiusDelta,
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
                child: Text('컨트롤', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textPrimary)),
              ),
              Text('${points.length}점', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800)),
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
          if (onAddPointFallback != null || onSetJailCenterFallback != null) ...[
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
          Text('감옥 반경', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
                IconButton(
                  tooltip: '-',
                  onPressed: () => onRadiusDelta(-_radiusStepM),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  color: AppColors.textSecondary,
                ),
              Expanded(
                child: Center(
                  child: Text(
                    (jailRadiusM == null) ? '—' : '${jailRadiusM!.round()}m',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
                IconButton(
                  tooltip: '+',
                  onPressed: () => onRadiusDelta(_radiusStepM),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '폴리곤은 최소 3점이 필요합니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
