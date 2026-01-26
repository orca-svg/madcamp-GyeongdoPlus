import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/ws_status_pill.dart';
import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/ws_ui_status_provider.dart';
import '../../features/zone/zone_editor_screen.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final me = room.me;
    final wsUi = ref.watch(wsUiStatusProvider);
    final rules = ref.watch(matchRulesProvider);
    final teamV = _teamValidation(room: room, rules: rules);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    Text('로비', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      tooltip: '나가기',
                      onPressed: () {
                        ref.read(roomProvider.notifier).leaveRoom();
                        ref.read(gamePhaseProvider.notifier).toOffGame();
                      },
                      icon: const Icon(
                        Icons.exit_to_app_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: WsStatusPill(
                    model: wsUi,
                    // Offline stage: do not allow WS reconnect actions.
                    onReconnect: null,
                  ),
                ),
                const SizedBox(height: 10),
                _RoomCodeCard(
                  roomCode: room.roomCode,
                  onCopy: room.roomCode.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: room.roomCode),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('방 코드가 복사되었습니다')),
                          );
                        },
                ),
                const SizedBox(height: 12),
                _RoomConfigSummaryCard(rules: rules),
                const SizedBox(height: 12),
                _TeamDistributionCard(
                  rules: rules,
                  onPoliceChanged: room.amIHost
                      ? (v) => ref
                            .read(matchRulesProvider.notifier)
                            .setPoliceCount(v)
                      : null,
                ),
                const SizedBox(height: 16),
                Text('참가자', style: Theme.of(context).textTheme.titleMedium),
                if (me?.ready ?? false) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Ready 해제 후 팀 변경 가능',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 12),
                GlowCard(
                  glow: true,
                  glowColor: AppColors.borderCyan.withOpacity(0.10),
                  borderColor: AppColors.borderCyan.withOpacity(0.35),
                  child: room.inRoom
                      ? ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: room.members.length,
                          separatorBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(
                              color: AppColors.outlineLow,
                              height: 1,
                            ),
                          ),
                          itemBuilder: (context, i) {
                            final m = room.members[i];
                            return _MemberRow(
                              member: m,
                              isMe: m.id == room.myId,
                              onTeamSelected:
                                  (m.id == room.myId && !(me?.ready ?? false))
                                  ? (t) => ref
                                        .read(roomProvider.notifier)
                                        .setMyTeam(t)
                                  : null,
                            );
                          },
                        )
                      : _EmptyRoomCard(
                          onGoHome: () =>
                              ref.read(gamePhaseProvider.notifier).toOffGame(),
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '경기 규칙',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (room.amIHost)
                      TextButton(
                        onPressed: room.inRoom
                            ? () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => _EditRulesSheet(
                                  initial: rules,
                                  onSave: (next) {
                                    final ctrl = ref.read(
                                      matchRulesProvider.notifier,
                                    );
                                    ctrl.setGameMode(next.gameMode);
                                    ctrl.setDurationMin(next.durationMin);
                                    ctrl.setMaxPlayers(next.maxPlayers);
                                    ctrl.setReleaseMode(next.releaseMode);
                                    ctrl.setMapName(next.mapName);

                                    // TODO: 서버 룰 싱크 메시지(action/rules_update 등) 스키마 확정 후 WS로 전송.
                                  },
                                  onEditZone: () {
                                    Navigator.of(context).pop(); // close sheet
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const ZoneEditorScreen(),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.borderCyan,
                        ),
                        child: const Text('편집'),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface2.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.outlineLow),
                        ),
                        child: const Text(
                          'READ ONLY',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _RulesSummaryCard(rules: rules, readOnly: !room.amIHost),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        key: const Key('lobbyReadyButton'),
                        variant: GradientButtonVariant.joinRoom,
                        title: (me?.ready ?? false) ? '준비 해제' : '준비 완료',
                        onPressed: room.inRoom
                            ? () =>
                                  ref.read(roomProvider.notifier).toggleReady()
                            : null,
                        leading: Icon(
                          (me?.ready ?? false)
                              ? Icons.undo_rounded
                              : Icons.check_circle_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        key: const Key('lobbyStartButton'),
                        variant: GradientButtonVariant.createRoom,
                        title: '경기 시작',
                        onPressed: (room.amIHost && teamV.ok)
                            ? () async {
                                await showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppColors.surface1,
                                    title: const Text('준비 중'),
                                    content: const Text(
                                      '이번 단계에서는 실제 시작(phase 전환/WS)을 비활성화했습니다.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('확인'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                        leading: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (room.amIHost && !teamV.ok) ...[
                  const SizedBox(height: 10),
                  _StartBlockedCard(v: teamV),
                ],
                const SizedBox(height: 10),
                _StartHelper(room: room),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      TextButton(
                        onPressed: room.inRoom
                            ? () => ref
                                  .read(roomProvider.notifier)
                                  .addFakeMember()
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                        ),
                        child: const Text('+ 봇 추가'),
                      ),
                      TextButton(
                        onPressed: room.inRoom
                            ? () => ref
                                  .read(roomProvider.notifier)
                                  .toggleFakeReadyAll()
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                        ),
                        child: const Text('봇 READY 토글'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomCodeCard extends StatelessWidget {
  final String roomCode;
  final VoidCallback? onCopy;

  const _RoomCodeCard({required this.roomCode, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glow: false,
      gradientSurface: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.borderCyan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderCyan.withOpacity(0.25)),
            ),
            child: const Icon(
              Icons.vpn_key_rounded,
              color: AppColors.borderCyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '방 코드',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  roomCode.isEmpty ? '—' : roomCode,
                  key: const Key('roomCodeText'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '복사',
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _RulesSummaryCard extends StatelessWidget {
  final MatchRulesState rules;
  final bool readOnly;

  const _RulesSummaryCard({required this.rules, required this.readOnly});

  @override
  Widget build(BuildContext context) {
    final poly = rules.zonePolygon;
    final zoneText = (poly == null || poly.isEmpty)
        ? '미설정(—)'
        : (poly.length >= 3
              ? '${poly.length}점 설정됨'
              : '점이 ${poly.length}개(최소 3)');
    final jailText = (rules.jailCenter != null && rules.jailRadiusM != null)
        ? '설정됨 (${rules.jailRadiusM!.round()}m)'
        : '미설정(—)';
    return GlowCard(
      glow: false,
      borderColor: readOnly
          ? AppColors.outlineLow
          : AppColors.borderCyan.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ruleRow(label: '모드', value: rules.gameMode.label),
          const SizedBox(height: 10),
          _ruleRow(label: '경기 시간', value: '${rules.durationMin}분'),
          const SizedBox(height: 10),
          _ruleRow(label: '인원', value: '${rules.maxPlayers}명'),
          const SizedBox(height: 10),
          _ruleRow(label: '해방 방식', value: rules.releaseMode),
          const SizedBox(height: 10),
          _ruleRow(label: '맵', value: rules.mapName),
          const SizedBox(height: 10),
          _ruleRow(label: '구역', value: zoneText),
          const SizedBox(height: 10),
          _ruleRow(label: '감옥', value: jailText),
          if (readOnly) ...[
            const SizedBox(height: 12),
            Text(
              '방장이 설정한 규칙을 확인할 수 있습니다.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ruleRow({required String label, required String value}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RoomConfigSummaryCard extends StatelessWidget {
  final MatchRulesState rules;

  const _RoomConfigSummaryCard({required this.rules});

  @override
  Widget build(BuildContext context) {
    final poly = rules.zonePolygon;
    final polyText = (poly == null || poly.isEmpty)
        ? '미설정'
        : (poly.length >= 3 ? '${poly.length}점' : '${poly.length}점(최소 3)');

    final jailCenterText = (rules.jailCenter == null)
        ? '미설정'
        : '${rules.jailCenter!.lat.toStringAsFixed(4)}, ${rules.jailCenter!.lng.toStringAsFixed(4)}';

    final jailRadiusText = (rules.jailRadiusM == null)
        ? '—'
        : '${rules.jailRadiusM!.round()}m';

    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text('현재 방 설정', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface2.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.outlineLow),
                ),
                child: const Text(
                  'OFFLINE',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ruleRow(label: '모드', value: rules.gameMode.wire),
          const SizedBox(height: 10),
          _ruleRow(
            label: '팀 분배',
            value:
                '경찰 ${rules.policeCount} / 도둑 ${rules.maxPlayers - rules.policeCount} (총 ${rules.maxPlayers})',
          ),
          const SizedBox(height: 10),
          _ruleRow(label: '인원', value: '${rules.maxPlayers}명'),
          const SizedBox(height: 10),
          _ruleRow(label: '시간', value: '${rules.timeLimitSec}s'),
          const SizedBox(height: 10),
          _ruleRow(label: 'contactMode', value: rules.contactMode),
          const SizedBox(height: 10),
          _ruleRow(
            label: '감옥',
            value:
                '${rules.jailEnabled ? 'ON' : 'OFF'} • radius=$jailRadiusText • center=$jailCenterText',
          ),
          const SizedBox(height: 10),
          _ruleRow(label: '폴리곤', value: polyText),
        ],
      ),
    );
  }

  Widget _ruleRow({required String label, required String value}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamDistributionCard extends StatelessWidget {
  final MatchRulesState rules;
  final ValueChanged<int>? onPoliceChanged;

  const _TeamDistributionCard({
    required this.rules,
    required this.onPoliceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxPlayers = rules.maxPlayers.clamp(2, 12);
    final minPolice = 1;
    final maxPolice = (maxPlayers - 1).clamp(1, 11);
    final police = rules.policeCount.clamp(minPolice, maxPolice);
    final thief = maxPlayers - police;

    final enabled = onPoliceChanged != null;

    return GlowCard(
      glow: false,
      borderColor: enabled
          ? AppColors.borderCyan.withOpacity(0.35)
          : AppColors.outlineLow,
      child: Opacity(
        opacity: enabled ? 1 : 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('팀 분배', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (!enabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface2.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.outlineLow),
                    ),
                    child: const Text(
                      'READ ONLY',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '경찰 $police / 도둑 $thief (총 $maxPlayers)',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              enabled ? '슬라이더로 경찰 수를 조정하세요.' : '팀 분배는 방장만 변경할 수 있어요.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            AbsorbPointer(
              absorbing: !enabled,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.borderCyan,
                  inactiveTrackColor: AppColors.outlineLow.withOpacity(0.9),
                  thumbColor: AppColors.borderCyan,
                  overlayColor: AppColors.borderCyan.withOpacity(0.12),
                ),
                child: Slider(
                  min: minPolice.toDouble(),
                  max: maxPolice.toDouble(),
                  divisions: (maxPolice - minPolice),
                  value: police.toDouble(),
                  onChanged: (v) => onPoliceChanged?.call(v.round()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamValidationResult {
  final int requiredPolice;
  final int requiredThief;
  final int currentPolice;
  final int currentThief;

  const _TeamValidationResult({
    required this.requiredPolice,
    required this.requiredThief,
    required this.currentPolice,
    required this.currentThief,
  });

  bool get ok =>
      requiredPolice == currentPolice && requiredThief == currentThief;

  String get mismatchMessage =>
      '팀 인원이 규칙과 맞지 않습니다. (경찰 $requiredPolice/도둑 $requiredThief 필요, 현재 경찰 $currentPolice/도둑 $currentThief)';
}

_TeamValidationResult _teamValidation({
  required RoomState room,
  required MatchRulesState rules,
}) {
  final maxPlayers = rules.maxPlayers.clamp(2, 12);
  final requiredPolice = rules.policeCount.clamp(1, maxPlayers - 1);
  final requiredThief = maxPlayers - requiredPolice;

  final currentPolice = room.effectivePoliceCount;
  final currentThief = room.effectiveThiefCount;

  return _TeamValidationResult(
    requiredPolice: requiredPolice,
    requiredThief: requiredThief,
    currentPolice: currentPolice,
    currentThief: currentThief,
  );
}

class _StartBlockedCard extends StatelessWidget {
  final _TeamValidationResult v;

  const _StartBlockedCard({required this.v});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.orange,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v.mismatchMessage,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.surface1,
                title: const Text('시작 불가'),
                content: Text(v.mismatchMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
            child: const Text('자세히'),
          ),
        ],
      ),
    );
  }
}

class _EditRulesSheet extends StatefulWidget {
  final MatchRulesState initial;
  final ValueChanged<MatchRulesState> onSave;
  final VoidCallback onEditZone;

  const _EditRulesSheet({
    required this.initial,
    required this.onSave,
    required this.onEditZone,
  });

  @override
  State<_EditRulesSheet> createState() => _EditRulesSheetState();
}

class _EditRulesSheetState extends State<_EditRulesSheet> {
  late MatchRulesState _draft;

  static const _maps = ['도심', '공원', '지하철', '캠퍼스'];
  static const _releaseModes = ['터치/근접', '버튼(3초)', '아이템 사용'];

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset + 18),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: GlowCard(
          glow: false,
          borderColor: AppColors.borderCyan.withOpacity(0.35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '경기 규칙 편집',
                    style: Theme.of(context).textTheme.titleMedium,
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
              const SizedBox(height: 10),
              Text(
                '모드',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final m in GameMode.values)
                    _chip(
                      selected: _draft.gameMode == m,
                      label: m.label,
                      onTap: () =>
                          setState(() => _draft = _draft.copyWith(gameMode: m)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _stepperRow(
                title: '경기 시간',
                valueText: '${_draft.durationMin}분',
                min: 5,
                max: 30,
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(durationMin: v)),
                value: _draft.durationMin,
              ),
              const SizedBox(height: 10),
              _stepperRow(
                title: '인원',
                valueText: '${_draft.maxPlayers}명',
                min: 2,
                max: 10,
                onChanged: (v) =>
                    setState(() => _draft = _draft.copyWith(maxPlayers: v)),
                value: _draft.maxPlayers,
              ),
              const SizedBox(height: 14),
              Text(
                '해방 방식',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final v in _releaseModes)
                    _chip(
                      selected: _draft.releaseMode == v,
                      label: v,
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(releaseMode: v),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '맵',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final v in _maps)
                    _chip(
                      selected: _draft.mapName == v,
                      label: v,
                      onTap: () =>
                          setState(() => _draft = _draft.copyWith(mapName: v)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('lobbyZoneEditButton'),
                onPressed: widget.onEditZone,
                icon: const Icon(Icons.map_outlined),
                label: const Text('구역 설정'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      variant: GradientButtonVariant.createRoom,
                      title: '저장',
                      onPressed: () {
                        widget.onSave(_draft);
                        Navigator.of(context).pop();
                      },
                      leading: const Icon(
                        Icons.save_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  Widget _stepperRow({
    required String title,
    required String valueText,
    required int min,
    required int max,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ),
        IconButton(
          tooltip: '-',
          onPressed: value <= min ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: AppColors.textSecondary,
        ),
        Text(
          valueText,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        IconButton(
          tooltip: '+',
          onPressed: value >= max ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final RoomMember member;
  final bool isMe;
  final ValueChanged<Team>? onTeamSelected;

  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.onTeamSelected,
  });

  @override
  Widget build(BuildContext context) {
    final teamLabel = member.team == Team.police ? '경찰' : '도둑';
    final teamColor = member.team == Team.police
        ? AppColors.borderCyan
        : AppColors.red;
    final readyColor = member.ready ? AppColors.lime : AppColors.textMuted;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: teamColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: teamColor.withOpacity(0.25)),
          ),
          child: Icon(
            member.team == Team.police
                ? Icons.shield_rounded
                : Icons.lock_rounded,
            color: teamColor,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      member.name + (isMe ? ' (나)' : ''),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (member.isHost) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 16,
                      color: AppColors.orange,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (isMe && onTeamSelected != null)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _teamChip(
                      label: '경찰',
                      selected: member.team == Team.police,
                      color: AppColors.borderCyan,
                      onTap: () => onTeamSelected!(Team.police),
                    ),
                    _teamChip(
                      label: '도둑',
                      selected: member.team == Team.thief,
                      color: AppColors.red,
                      onTap: () => onTeamSelected!(Team.thief),
                    ),
                  ],
                )
              else
                _pill(
                  text: teamLabel,
                  border: teamColor.withOpacity(0.55),
                  fill: teamColor.withOpacity(0.12),
                  textColor: teamColor,
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _pill(
          text: member.ready ? 'READY' : 'WAIT',
          border: readyColor.withOpacity(member.ready ? 0.55 : 0.35),
          fill: readyColor.withOpacity(0.12),
          textColor: readyColor,
        ),
      ],
    );
  }

  Widget _teamChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.35),
            width: AppDimens.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _pill({
    required String text,
    required Color border,
    required Color fill,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: AppDimens.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _StartHelper extends StatelessWidget {
  final RoomState room;

  const _StartHelper({required this.room});

  @override
  Widget build(BuildContext context) {
    String msg;
    if (!room.inRoom) {
      msg = '방에 참가해야 시작할 수 있습니다.';
    } else if (!room.amIHost) {
      msg = '방장만 시작할 수 있습니다.';
    } else if (!room.allReady) {
      msg = '모든 참가자가 READY여야 합니다.';
    } else {
      msg = '준비 완료! 경기를 시작하세요.';
    }

    final ok = room.amIHost && room.allReady;
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          size: 16,
          color: ok ? AppColors.lime : AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _EmptyRoomCard extends StatelessWidget {
  final VoidCallback onGoHome;

  const _EmptyRoomCard({required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('방 정보가 없습니다.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '홈에서 방을 만들거나 참여해주세요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          GradientButton(
            variant: GradientButtonVariant.joinRoom,
            title: '홈으로',
            onPressed: onGoHome,
            leading: const Icon(Icons.home_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
