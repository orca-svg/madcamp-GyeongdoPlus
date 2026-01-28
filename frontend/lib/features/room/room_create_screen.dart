import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/room_provider.dart';
import '../zone/zone_editor_screen.dart';
import 'room_create_payload.dart';

class RoomCreateScreen extends ConsumerStatefulWidget {
  const RoomCreateScreen({super.key});

  @override
  ConsumerState<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends ConsumerState<RoomCreateScreen> {
  RoomCreateFormState _form = RoomCreateFormState.initial();
  bool _submitting = false;

  void _setMode(RoomCreateMode mode) =>
      setState(() => _form = _form.copyWith(mode: mode));
  void _setMaxPlayers(int v) =>
      setState(() => _form = _form.copyWith(maxPlayers: v.clamp(3, 50)));
  void _setTimeLimitSec(int v) =>
      setState(() => _form = _form.copyWith(timeLimitSec: v.clamp(300, 1800)));
  void _setContactMode(RoomContactMode v) =>
      setState(() => _form = _form.copyWith(contactMode: v));
  void _setReleaseScope(RoomReleaseScope v) =>
      setState(() => _form = _form.copyWith(releaseScope: v));
  void _setReleaseOrder(RoomReleaseOrder v) =>
      setState(() => _form = _form.copyWith(releaseOrder: v));
  void _setPoliceRatio(double v) =>
      setState(() => _form = _form.copyWith(policeRatio: v));

  Future<void> _openZoneSetup() async {
    debugPrint(
      '[KAKAO] If map is black, ensure Web platform domain includes localhost/127.0.0.1',
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ZoneEditorScreen()),
    );
    final rules = ref.read(matchRulesProvider);
    setState(
      () => _form = _form.copyWith(
        polygon: rules.zonePolygon,
        jailCenter: rules.jailCenter,
        jailRadiusM: rules.jailRadiusM,
      ),
    );
  }

  Future<void> _onCreatePressed() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final payload = buildRoomCreatePayload(_form);
    debugPrint('[ROOM_CREATE] payload=$payload');

    ref.read(matchRulesProvider.notifier).applyOfflineRoomConfig(payload);
    final success = await ref
        .read(roomProvider.notifier)
        .createRoom(myName: '김선수');
    if (!mounted) return;
    if (success) {
      ref.read(gamePhaseProvider.notifier).toLobby();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      final roomState = ref.read(roomProvider);
      showAppSnackBar(
        context,
        message: roomState.errorMessage ?? '방 생성에 실패했습니다',
        isError: true,
      );
    }
    setState(() => _submitting = false);

    _createRoomHook(payload);
  }

  void _createRoomHook(Map<String, dynamic> payload) {
    debugPrint(
      '[ROOM_CREATE] hook called (no-op) keys=${payload.keys.toList()}',
    );
  }

  Widget _buildMapPreview(BuildContext context) {
    // Only show map if API key exists
    final hasKey =
        dotenv.isInitialized &&
        (dotenv.env['KAKAO_JS_APP_KEY']?.isNotEmpty ?? false);
    if (!hasKey) {
      return const Center(child: Text('Map Key Missing'));
    }

    final points = _form.polygon ?? [];
    final center = points.isNotEmpty
        ? _centroid(points)
        : LatLng(37.5665, 126.9780); // Default Seoul

    return KakaoMap(
      center: center,
      currentLevel: 4,
      zoomControl: false,
      mapTypeControl: false,
      polygons: points.length >= 3
          ? [
              Polygon(
                polygonId: 'preview_poly',
                points: points.map((p) => LatLng(p.lat, p.lng)).toList(),
                strokeWidth: 2,
                strokeColor: AppColors.borderCyan,
                strokeOpacity: 0.9,
                fillColor: AppColors.borderCyan,
                fillOpacity: 0.14,
                zIndex: 1,
              ),
            ]
          : null,
      circles: (_form.jailCenter != null)
          ? [
              Circle(
                circleId: 'preview_jail',
                center: LatLng(_form.jailCenter!.lat, _form.jailCenter!.lng),
                radius: _form.jailRadiusM ?? 15.0,
                strokeWidth: 2,
                strokeColor: AppColors.purple,
                strokeOpacity: 0.9,
                fillColor: AppColors.purple,
                fillOpacity: 0.12,
                zIndex: 2,
              ),
            ]
          : null,
      // No markers as requested
    );
  }

  LatLng _centroid(List<GeoPointDto> points) {
    if (points.isEmpty) return LatLng(37.5665, 126.9780);
    double lat = 0;
    double lng = 0;
    for (var p in points) {
      lat += p.lat;
      lng += p.lng;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('방 만들기'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionCard(
                        title: null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '모드',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _ModeSegmented(
                              mode: _form.mode,
                              onChanged: _setMode,
                            ),
                            const SizedBox(height: 12),
                            _LabeledRow(
                              label: '인원',
                              trailing: Text(
                                '${_form.maxPlayers}명',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Slider(
                              min: 3,
                              max: 50,
                              divisions: 47,
                              value: _form.maxPlayers.toDouble(),
                              onChanged: (v) => _setMaxPlayers(v.round()),
                            ),
                            const SizedBox(height: 6),
                            // Ratio Slider
                            Slider(
                              min: 0.1,
                              max: 0.5,
                              divisions: 4,
                              value: _form.policeRatio,
                              onChanged: _setPoliceRatio,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '경찰 ${(_form.maxPlayers * _form.policeRatio).round()}명',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.borderCyan,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  '도둑 ${(_form.maxPlayers - (_form.maxPlayers * _form.policeRatio).round())}명',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.red,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _LabeledRow(
                              label: '시간',
                              trailing: Text(
                                _fmtTime(_form.timeLimitSec),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Slider(
                              min: 300,
                              max: 1800,
                              divisions: 25,
                              value: _form.timeLimitSec.toDouble(),
                              onChanged: (v) =>
                                  _setTimeLimitSec((v / 60).round() * 60),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: '경기장 설정',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.outlineLow),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildMapPreview(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openZoneSetup,
                                icon: const Icon(Icons.tune_rounded, size: 18),
                                label: const Text('경기장 설정'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: '해방 규칙',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .stretch, // Stretch for full width buttons
                          children: [
                            _ToggleChips<RoomContactMode>(
                              value: _form.contactMode,
                              onChanged: _setContactMode,
                              items: const [
                                _ToggleItem(
                                  value: RoomContactMode.nonContact,
                                  label: '비접촉',
                                ),
                                _ToggleItem(
                                  value: RoomContactMode.contact,
                                  label: '접촉',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _ToggleChips<RoomReleaseScope>(
                              value: _form.releaseScope,
                              onChanged: _setReleaseScope,
                              items: const [
                                _ToggleItem(
                                  value: RoomReleaseScope.partial,
                                  label: '일부\n(인원수 제한)',
                                ),
                                _ToggleItem(
                                  value: RoomReleaseScope.all,
                                  label: '전체\n(모두 해방)',
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _form.releaseScope == RoomReleaseScope.partial
                                  ? '설정된 인원수만큼만 해방됩니다.'
                                  : '감옥의 모든 사람이 해방됩니다.',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            // Always show Order options, or conditionally?
                            // User request: "Split order choices... remove labels"
                            // Assuming we show it. Logic: if scope is All, maybe order doesn't matter?
                            // Existing logic: if (_form.releaseScope == RoomReleaseScope.partial)
                            if (_form.releaseScope ==
                                RoomReleaseScope.partial) ...[
                              _ToggleChips<RoomReleaseOrder>(
                                value: _form.releaseOrder,
                                onChanged: _setReleaseOrder,
                                items: const [
                                  _ToggleItem(
                                    value: RoomReleaseOrder.fifo,
                                    label: '선착순\n(먼저 잡힌 순)',
                                  ),
                                  _ToggleItem(
                                    value: RoomReleaseOrder.lifo,
                                    label: '후착순\n(나중에 잡힌 순)',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _form.releaseOrder == RoomReleaseOrder.fifo
                                      ? '먼저 잡힌 사람이 우선 해방됩니다.'
                                      : '나중에 잡힌 사람이 우선 해방됩니다.',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: AppColors.textMuted),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: GradientButton(
                      variant: GradientButtonVariant.createRoom,
                      title: _submitting ? '생성 중...' : '방 생성',
                      height: 56,
                      borderRadius: 16,
                      onPressed: _submitting ? null : _onCreatePressed,
                      leading: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                            ),
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

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  final String label;
  final Widget trailing;

  const _LabeledRow({required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _ModeSegmented extends StatelessWidget {
  final RoomCreateMode mode;
  final ValueChanged<RoomCreateMode> onChanged;

  const _ModeSegmented({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget item(RoomCreateMode value, String label) {
      final selected = mode == value;
      final color = selected ? AppColors.borderCyan : AppColors.outlineLow;
      final fill = selected
          ? AppColors.borderCyan.withOpacity(0.18)
          : AppColors.surface2.withOpacity(0.25);
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(value),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(selected ? 0.6 : 0.9),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        item(RoomCreateMode.normal, '일반'),
        const SizedBox(width: 8),
        item(RoomCreateMode.item, '아이템'),
        const SizedBox(width: 8),
        item(RoomCreateMode.ability, '능력'),
      ],
    );
  }
}

class _ToggleItem<T> {
  final T value;
  final String label;
  const _ToggleItem({required this.value, required this.label});
}

class _ToggleChips<T> extends StatelessWidget {
  final T value;
  final ValueChanged<T> onChanged;
  final List<_ToggleItem<T>> items;

  const _ToggleChips({
    required this.value,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChanged(item.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: value == item.value
                    ? AppColors.borderCyan.withOpacity(0.18)
                    : AppColors.surface2.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      (value == item.value
                              ? AppColors.borderCyan
                              : AppColors.outlineLow)
                          .withOpacity(0.8),
                ),
              ),
              child: Text(
                item.label,
                style: TextStyle(
                  color: value == item.value
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _fmtTime(int sec) {
  final m = (sec / 60).round();
  return '$m분';
}
