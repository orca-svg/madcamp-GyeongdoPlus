import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../zone/zone_setup_placeholder_screen.dart';
import 'room_create_payload.dart';

class RoomCreateScreen extends StatefulWidget {
  const RoomCreateScreen({super.key});

  @override
  State<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends State<RoomCreateScreen> {
  RoomCreateFormState _form = RoomCreateFormState.initial();

  void _setMode(RoomCreateMode mode) =>
      setState(() => _form = _form.copyWith(mode: mode));
  void _setMaxPlayers(int v) =>
      setState(() => _form = _form.copyWith(maxPlayers: v.clamp(2, 12)));
  void _setTimeLimitSec(int v) =>
      setState(() => _form = _form.copyWith(timeLimitSec: v.clamp(300, 1800)));
  void _setContactMode(RoomContactMode v) =>
      setState(() => _form = _form.copyWith(contactMode: v));
  void _setJailEnabled(bool v) =>
      setState(() => _form = _form.copyWith(jailEnabled: v));

  Future<void> _openZoneSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ZoneSetupPlaceholderScreen(),
      ),
    );
  }

  void _onCreatePressed() {
    final payload = buildRoomCreatePayload(_form);
    debugPrint('[ROOM_CREATE] payload=$payload');

    // TODO(Step next): connect to providers + transition to lobby after WS handshake.
    _createRoomHook(payload);
  }

  void _createRoomHook(Map<String, dynamic> payload) {
    debugPrint(
      '[ROOM_CREATE] hook called (no-op) keys=${payload.keys.toList()}',
    );
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
                        title: '모드 / 인원 / 시간',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ModeSelector(
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
                              min: 2,
                              max: 12,
                              divisions: 10,
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
                              divisions: 25, // 60s step
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
                              '폴리곤: 미설정',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '감옥 반경: 12m',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
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
                        title: '체포 규칙',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LabeledRow(
                              label: 'contactMode',
                              trailing: DropdownButton<RoomContactMode>(
                                value: _form.contactMode,
                                dropdownColor: AppColors.surface1,
                                underline: const SizedBox.shrink(),
                                items: const [
                                  DropdownMenuItem(
                                    value: RoomContactMode.nonContact,
                                    child: Text('NON_CONTACT'),
                                  ),
                                  DropdownMenuItem(
                                    value: RoomContactMode.contact,
                                    child: Text('CONTACT'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    v == null ? null : _setContactMode(v),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: '감옥 / 구출 / 레이더',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: _form.jailEnabled,
                              onChanged: _setJailEnabled,
                              title: const Text(
                                '감옥 사용',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '반경 12m (고정)',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                            ),
                            const Divider(
                              color: AppColors.outlineLow,
                              height: 1,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '구출: CHANNELING • range=10m • channel=8000ms • release=3 • FIFO',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '상대 공개: LIMITED • radarPingTtlMs=7000',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
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
                      title: '방 생성',
                      height: 56,
                      borderRadius: 16,
                      onPressed: _onCreatePressed,
                      leading: const Icon(
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

class _ModeSelector extends StatelessWidget {
  final RoomCreateMode mode;
  final ValueChanged<RoomCreateMode> onChanged;

  const _ModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip({required RoomCreateMode value, required String label}) {
      final selected = mode == value;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface2.withOpacity(selected ? 0.45 : 0.25),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: (selected ? AppColors.borderCyan : AppColors.outlineLow)
                  .withOpacity(0.9),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        chip(value: RoomCreateMode.normal, label: 'NORMAL'),
        chip(value: RoomCreateMode.item, label: 'ITEM'),
        chip(value: RoomCreateMode.ability, label: 'ABILITY'),
      ],
    );
  }
}

String _fmtTime(int sec) {
  final m = (sec / 60).round();
  return '$m분 ($sec s)';
}
