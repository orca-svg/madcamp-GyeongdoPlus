import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/neon_radio_group.dart';
import '../../features/zone/zone_editor_screen.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/room_provider.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final rules = ref.watch(matchRulesProvider);
    final phase = ref.watch(gamePhaseProvider);
    final bottomInset = (phase == GamePhase.offGame
        ? AppDimens.bottomBarHOff
        : AppDimens.bottomBarHIn) +
        18;

    final me = room.me;
    final isHost = room.amIHost;
    final allReady = room.allReady;
    final totalPlayers = room.members.length;
    final canStart = isHost && allReady && totalPlayers >= 2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _roomInfoCard(context, room, rules.maxPlayers),
                      const SizedBox(height: 12),
                      _rulesSummaryCard(context, room, rules),
                      const SizedBox(height: 12),
                      if (isHost) ...[
                        _rulesEditCard(context, ref, rules),
                        const SizedBox(height: 12),
                      ],
                      if (kDebugMode) ...[
                        _devBotCard(context),
                        const SizedBox(height: 12),
                      ],
                      _membersCard(context, ref, room, me),
                      const SizedBox(height: 12),
                      _teamSection(context, ref, me),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(roomProvider.notifier).leaveRoom();
                          ref.read(gamePhaseProvider.notifier).toOffGame();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: AppColors.outlineLow),
                        ),
                        child: const Text('나가기'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        key: const Key('lobbyStartButton'),
                        variant: GradientButtonVariant.createRoom,
                        title: '게임 시작',
                        height: 54,
                        borderRadius: 16,
                        onPressed: canStart
                            ? () {
                                ref.read(gamePhaseProvider.notifier).toInGame();
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
                const SizedBox(height: 10),
                if (!isHost)
                  Text(
                    '게임 시작은 방장만 가능합니다.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  )
                else if (totalPlayers < 2)
                  Text(
                    '최소 2명 이상이어야 시작할 수 있습니다.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  )
                else if (!allReady)
                  Text(
                    '모든 멤버가 준비되어야 시작할 수 있습니다.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roomInfoCard(
    BuildContext context,
    RoomState room,
    int maxPlayers,
  ) {
    RoomMember? host;
    for (final m in room.members) {
      if (m.isHost) {
        host = m;
        break;
      }
    }
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.meeting_room_rounded, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '로비',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '방 코드: ${room.roomCode.isEmpty ? '—' : room.roomCode}',
                  key: const Key('roomCodeText'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '인원: ${room.members.length} / $maxPlayers',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '방장: ${host?.name ?? '—'}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '복사',
            onPressed: room.roomCode.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(text: room.roomCode),
                    );
                    if (context.mounted) {
                      showAppSnackBar(context, message: '방 코드 복사 완료');
                    }
                  },
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _rulesSummaryCard(
    BuildContext context,
    RoomState room,
    MatchRulesState rules,
  ) {
    final polygonCount = rules.zonePolygon?.length ?? 0;
    final hasJailCenter = rules.jailCenter != null;
    final jailRadiusText = rules.jailRadiusM == null
        ? '미설정'
        : '${rules.jailRadiusM!.toStringAsFixed(0)}m';
    final policeCount = room.members.isNotEmpty
        ? room.policeCount
        : rules.policeCount;
    final thiefCount = room.members.isNotEmpty
        ? room.thiefCount
        : (rules.maxPlayers - rules.policeCount).clamp(0, 99);
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('규칙 요약', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          _ruleRow('모드', rules.gameMode.label),
          _ruleRow('시간 제한', '${(rules.timeLimitSec / 60).round()}분'),
          _ruleRow('접촉 방식', _contactLabel(rules.contactMode)),
          _ruleRow(
            '해방 규칙',
            '${_releaseScopeLabel(rules.rescueReleaseScope)}'
            '${rules.rescueReleaseScope == 'PARTIAL' ? ' · ${_releaseOrderLabel(rules.rescueReleaseOrder)}' : ''}',
          ),
          _ruleRow('경찰 수', '$policeCount'),
          _ruleRow('도둑 수', '$thiefCount'),
          _ruleRow('구역 점', polygonCount == 0 ? '미설정' : '$polygonCount개'),
          _ruleRow('감옥 중심', hasJailCenter ? '설정됨' : '미설정'),
          _ruleRow('감옥 반경', jailRadiusText),
        ],
      ),
    );
  }

  Widget _rulesEditCard(
    BuildContext context,
    WidgetRef ref,
    MatchRulesState rules,
  ) {
    final timeMin = 300.0;
    final timeMax = 1800.0;
    final timeSpan = ((timeMax - timeMin) / 60).round();
    final timeDivisions = timeSpan >= 1 ? timeSpan : null;
    final timeValue =
        rules.timeLimitSec.clamp(timeMin.toInt(), timeMax.toInt()).toDouble();

    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('규칙 수정', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Text(
            '시간 제한',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Slider(
            min: timeMin,
            max: timeMax,
            divisions: timeDivisions,
            value: timeValue,
            onChanged: (v) =>
                ref.read(matchRulesProvider.notifier).setTimeLimitSec(v.round()),
          ),
          const SizedBox(height: 6),
          Text(
            '${(rules.timeLimitSec / 60).round()}분',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Text('모드', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _modeChip(context, ref, rules, GameMode.normal),
              const SizedBox(width: 8),
              _modeChip(context, ref, rules, GameMode.item),
              const SizedBox(width: 8),
              _modeChip(context, ref, rules, GameMode.ability),
            ],
          ),
          const SizedBox(height: 14),
          Text('접촉 방식', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _contactChip(context, ref, rules, 'NON_CONTACT', '비접촉'),
              const SizedBox(width: 8),
              _contactChip(context, ref, rules, 'CONTACT', '접촉'),
            ],
          ),
          const SizedBox(height: 14),
          Text('해방 범위', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              _releaseScopeChip(context, rules, 'PARTIAL', '일부 해방'),
              const SizedBox(width: 8),
              _releaseScopeChip(context, rules, 'ALL', '전체 해방'),
            ],
          ),
          if (rules.rescueReleaseScope == 'PARTIAL') ...[
            const SizedBox(height: 10),
            Text('해방 순서', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                _releaseOrderChip(context, rules, 'FIFO', '선착순 해방'),
                const SizedBox(width: 8),
                _releaseOrderChip(context, rules, 'LIFO', '후착순 해방'),
              ],
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ZoneEditorScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: const BorderSide(color: AppColors.outlineLow),
            ),
            icon: const Icon(Icons.map_rounded, size: 18),
            label: const Text('구역 수정'),
          ),
        ],
      ),
    );
  }

  Widget _membersCard(
    BuildContext context,
    WidgetRef ref,
    RoomState room,
    RoomMember? me,
  ) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('멤버', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: room.members.length,
            separatorBuilder: (_, __) => const Divider(
              color: AppColors.outlineLow,
              height: 16,
            ),
            itemBuilder: (context, i) {
              final m = room.members[i];
              final isMe = m.id == room.myId;
              return _MemberRow(
                member: m,
                isMe: isMe,
                onReadyChanged: isMe
                    ? (v) => ref.read(roomProvider.notifier).setMyReady(v)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _teamSection(BuildContext context, WidgetRef ref, RoomMember? me) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('팀 선택', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          _TeamSelector(
            team: me?.team ?? Team.police,
            enabled: !(me?.ready ?? false),
            onChanged: (t) => ref.read(roomProvider.notifier).setMyTeam(t),
          ),
          if (me?.ready ?? false) ...[
            const SizedBox(height: 8),
            Text(
              'Ready 해제 후 변경 가능',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _devBotCard(BuildContext context) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Developer', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _devButton(context, '봇 +1', () {
                final ref = ProviderScope.containerOf(context);
                ref.read(roomProvider.notifier).addBots(count: 1);
              }),
              _devButton(context, '봇 +3', () {
                final ref = ProviderScope.containerOf(context);
                ref.read(roomProvider.notifier).addBots(count: 3);
              }),
              _devButton(context, '봇 전원 READY', () {
                final ref = ProviderScope.containerOf(context);
                ref.read(roomProvider.notifier).setBotsReady(ready: true);
              }),
              _devButton(context, '봇 전원 UNREADY', () {
                final ref = ProviderScope.containerOf(context);
                ref.read(roomProvider.notifier).setBotsReady(ready: false);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _devButton(BuildContext context, String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.outlineLow),
      ),
      child: Text(label),
    );
  }

  Widget _modeChip(
    BuildContext context,
    WidgetRef ref,
    MatchRulesState rules,
    GameMode mode,
  ) {
    final selected = rules.gameMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(matchRulesProvider.notifier).setGameMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.borderCyan.withOpacity(0.18)
                : AppColors.surface2.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected ? AppColors.borderCyan : AppColors.outlineLow,
            ),
          ),
          child: Text(
            mode.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactChip(
    BuildContext context,
    WidgetRef ref,
    MatchRulesState rules,
    String value,
    String label,
  ) {
    final selected = rules.contactMode == value;
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(matchRulesProvider.notifier).setContactMode(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.borderCyan.withOpacity(0.18)
                : AppColors.surface2.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected ? AppColors.borderCyan : AppColors.outlineLow,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _releaseScopeChip(
    BuildContext context,
    MatchRulesState rules,
    String value,
    String label,
  ) {
    final selected = rules.rescueReleaseScope == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          showAppSnackBar(
            context,
            message:
                'TODO: matchRulesProvider.notifier.setRescueReleaseScope() 연결 필요',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.borderCyan.withOpacity(0.18)
                : AppColors.surface2.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected ? AppColors.borderCyan : AppColors.outlineLow,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _releaseOrderChip(
    BuildContext context,
    MatchRulesState rules,
    String value,
    String label,
  ) {
    final selected = rules.rescueReleaseOrder == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          showAppSnackBar(
            context,
            message:
                'TODO: matchRulesProvider.notifier.setRescueReleaseOrder() 연결 필요',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.borderCyan.withOpacity(0.18)
                : AppColors.surface2.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected ? AppColors.borderCyan : AppColors.outlineLow,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _ruleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _contactLabel(String raw) => raw == 'CONTACT' ? '접촉' : '비접촉';
  String _releaseScopeLabel(String raw) => raw == 'ALL' ? '전체 해방' : '일부 해방';
  String _releaseOrderLabel(String raw) => raw == 'LIFO' ? '후착순' : '선착순';
}

class _MemberRow extends StatelessWidget {
  final RoomMember member;
  final bool isMe;
  final ValueChanged<bool>? onReadyChanged;

  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.onReadyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final teamIcon =
        member.team == Team.police ? Icons.shield_rounded : Icons.lock_rounded;
    final teamColor =
        member.team == Team.police ? AppColors.borderCyan : AppColors.orange;
    final readyText = member.ready ? 'READY' : 'WAIT';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(teamIcon, size: 18, color: teamColor),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (member.isHost) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface2.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.outlineLow),
                      ),
                      child: const Text(
                        'HOST',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ReadyPill(text: readyText),
          ],
        ),
        if (isMe && onReadyChanged != null) ...[
          const SizedBox(height: 8),
          NeonRadioGroup<bool>(
            value: member.ready,
            onChanged: onReadyChanged!,
            options: const [
              NeonRadioOption(
                value: false,
                label: 'NOT READY',
                color: AppColors.textMuted,
              ),
              NeonRadioOption(
                value: true,
                label: 'READY',
                color: AppColors.lime,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReadyPill extends StatelessWidget {
  final String text;

  const _ReadyPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final isReady = text == 'READY';
    final color = isReady ? AppColors.lime : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TeamSelector extends StatelessWidget {
  final Team team;
  final bool enabled;
  final ValueChanged<Team> onChanged;

  const _TeamSelector({
    required this.team,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget item(Team value, String label, IconData icon) {
      final selected = team == value;
      final color = selected ? AppColors.borderCyan : AppColors.outlineLow;
      final fill = selected
          ? AppColors.borderCyan.withOpacity(0.18)
          : AppColors.surface2.withOpacity(0.25);
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? () => onChanged(value) : null,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(selected ? 0.6 : 0.9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: AppColors.textPrimary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Row(
        children: [
          item(Team.police, '경찰', Icons.shield_rounded),
          const SizedBox(width: 10),
          item(Team.thief, '도둑', Icons.lock_rounded),
        ],
      ),
    );
  }
}
