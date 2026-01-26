import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/room_provider.dart';
import '../zone/zone_setup_placeholder_screen.dart';
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

  Future<void> _openZoneSetup() async {
    final result = await Navigator.of(context).push<ZoneSetupResult?>(
      MaterialPageRoute<ZoneSetupResult?>(
        builder: (_) => const ZoneSetupPlaceholderScreen(),
      ),
    );
    if (result == null) return;
    setState(
      () => _form = _form.copyWith(
        polygon: result.polygon,
        jailCenter: result.jailCenter,
        jailRadiusM: result.jailRadiusM,
      ),
    );
  }

  Future<void> _onCreatePressed() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final payload = buildRoomCreatePayload(_form);
    debugPrint('[ROOM_CREATE] payload=$payload');

    ref.read(matchRulesProvider.notifier).applyOfflineRoomConfig(payload);
    final result =
        await ref.read(roomProvider.notifier).createRoom(myName: '김선수');
    if (!mounted) return;
    if (result.ok) {
      ref.read(gamePhaseProvider.notifier).toLobby();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      showAppSnackBar(
        context,
        message: result.errorMessage ?? '방 생성에 실패했습니다',
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

  @override
  Widget build(BuildContext context) {
    final polygonCount = _form.polygon?.length ?? 0;
    final jailCenter = _form.jailCenter;
    final jailRadius = _form.jailRadiusM ?? 12;

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
                        title: '모드 / 인원 / 시간',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            _LabeledRow(
                              label: '시간 제한',
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
                        title: '구역 설정',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              polygonCount >= 3
                                  ? '폴리곤: ${polygonCount}점'
                                  : '폴리곤: 미설정',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              jailCenter == null
                                  ? '감옥: 미설정'
                                  : '감옥: ${jailCenter.lat.toStringAsFixed(4)}, ${jailCenter.lng.toStringAsFixed(4)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '감옥 반경: ${jailRadius.round()}m',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '감옥 위치/구역은 구역 설정에서 관리',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openZoneSetup,
                                icon: const Icon(Icons.tune_rounded, size: 18),
                                label: const Text('구역 설정'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: '해방 규칙',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LabeledRow(
                              label: '접촉 방식',
                              trailing: _ToggleChips<RoomContactMode>(
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
                            ),
                            const SizedBox(height: 12),
                            _LabeledRow(
                              label: '해방 범위',
                              trailing: _ToggleChips<RoomReleaseScope>(
                                value: _form.releaseScope,
                                onChanged: _setReleaseScope,
                                items: const [
                                  _ToggleItem(
                                    value: RoomReleaseScope.partial,
                                    label: '일부 해방',
                                  ),
                                  _ToggleItem(
                                    value: RoomReleaseScope.all,
                                    label: '전체 해방',
                                  ),
                                ],
                              ),
                            ),
                            if (_form.releaseScope == RoomReleaseScope.partial)
                              ...[
                                const SizedBox(height: 12),
                                _LabeledRow(
                                  label: '해방 순서',
                                  trailing: _ToggleChips<RoomReleaseOrder>(
                                    value: _form.releaseOrder,
                                    onChanged: _setReleaseOrder,
                                    items: const [
                                      _ToggleItem(
                                        value: RoomReleaseOrder.fifo,
                                        label: '선착순 해방',
                                      ),
                                      _ToggleItem(
                                        value: RoomReleaseOrder.lifo,
                                        label: '후착순 해방',
                                      ),
                                    ],
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
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
  final String title;
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
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
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
              border: Border.all(color: color.withOpacity(selected ? 0.6 : 0.9)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
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
                  color: (value == item.value
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
  return '$m분 ($sec s)';
}
