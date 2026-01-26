// Lobby UI overhaul with compact neon action bar and clearer ready/team UX.
// Why: reduce bottom bar space, remove overflow, and align rules summary with current edits.
// Adds host-only edit toggle with snackbar feedback and live rules summary updates.
// Provides neon radio team selection + READY/WAIТ toggle in a single "내 상태" card.
// Enforces start conditions (host/all ready/team distribution) with guidance text above the bar.
// Keeps debug bot tooling for local testing in kDebugMode.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);
    final rules = ref.watch(matchRulesProvider);
    final me = room.me;
    final isHost = room.amIHost;
    final allReady = room.allReady;
    final totalPlayers = room.members.length;
    final totalForRules = totalPlayers > 0 ? totalPlayers : rules.maxPlayers;
    final policeCount = rules.policeCount.clamp(0, totalForRules);
    final thiefCount = (totalForRules - policeCount).clamp(0, 99);
    final teamOk = policeCount >= 1 && thiefCount >= 1;
    final canStart = isHost && allReady && totalPlayers >= 2 && teamOk;
    final bottomBarHeight = 68.0;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomInset =
        bottomBarHeight + safeBottom + (isHost ? 32 : 28);

    final startNotice = _startNotice(
      isHost: isHost,
      totalPlayers: totalPlayers,
      allReady: allReady,
      teamOk: teamOk,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              ListView(
                padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset),
                children: [
                  _roomInfoCard(context, room, rules.maxPlayers),
                  const SizedBox(height: 12),
                  _myStatusCard(context, ref, me),
                  const SizedBox(height: 12),
                  _rulesSummaryCard(
                    context,
                    rules,
                    totalForRules: totalForRules,
                    onEditToggle: isHost
                        ? () {
                            setState(() => _editMode = !_editMode);
                            showAppSnackBar(
                              context,
                              message: '규칙 편집 모드 ON',
                              action: SnackBarAction(
                                label: '닫기',
                                onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                              ),
                            );
                          }
                        : null,
                    editEnabled: _editMode && isHost,
                  ),
                  const SizedBox(height: 12),
                  if (_editMode && isHost) ...[
                    _rulesEditCard(context, ref, rules, room),
                    const SizedBox(height: 12),
                  ],
                  if (kDebugMode) ...[
                    _devBotCard(context),
                    const SizedBox(height: 12),
                  ],
                  _membersCard(context, room),
                ],
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (startNotice.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            startNotice,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      _lobbyActionBar(
                        context,
                        ref,
                        canStart: canStart,
                        height: bottomBarHeight,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    MatchRulesState rules, {
    required int totalForRules,
    required VoidCallback? onEditToggle,
    required bool editEnabled,
  }) {
    final polygonCount = rules.zonePolygon?.length ?? 0;
    final hasJailCenter = rules.jailCenter != null;
    final jailRadiusText = rules.jailRadiusM == null
        ? '미설정'
        : '${rules.jailRadiusM!.toStringAsFixed(0)}m';
    final policeCount = rules.policeCount.clamp(0, totalForRules);
    final thiefCount = (totalForRules - policeCount).clamp(0, 99);
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '규칙 요약',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (onEditToggle != null)
                TextButton(
                  onPressed: onEditToggle,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        editEnabled ? AppColors.borderCyan : AppColors.textMuted,
                  ),
                  child: Text(editEnabled ? '편집 중' : '편집'),
                ),
            ],
          ),
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
    RoomState room,
  ) {
    final totalPlayers = room.members.length;
    final totalForRules = totalPlayers > 0 ? totalPlayers : rules.maxPlayers;
    final policeMin = totalForRules >= 2 ? 1 : 0;
    final policeMax = totalForRules >= 2 ? totalForRules - 1 : 0;
    final policeValue = rules.policeCount
        .clamp(policeMin, policeMax == 0 ? policeMin : policeMax)
        .toDouble();
    final policeDivisions =
        (policeMax - policeMin) >= 1 ? (policeMax - policeMin) : null;
    final thiefCount = (totalForRules - policeValue.round()).clamp(0, 99);
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
            '경찰 수',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Slider(
            min: policeMin.toDouble(),
            max: policeMax.toDouble(),
            divisions: policeDivisions,
            value: policeValue,
            onChanged: totalForRules >= 2
                ? (v) => ref
                    .read(matchRulesProvider.notifier)
                    .setPoliceCount(v.round())
                : null,
          ),
          Text(
            '도둑 수: $thiefCount',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted),
          ),
          if (totalForRules < 2) ...[
            const SizedBox(height: 6),
            Text(
              '참가자 2명 이상부터 팀 분배가 가능합니다.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 14),
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
    RoomState room,
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
              return _MemberRow(
                member: m,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _myStatusCard(BuildContext context, WidgetRef ref, RoomMember? me) {
    final team = me?.team ?? Team.police;
    final ready = me?.ready ?? false;
    final teamColor = team == Team.police ? AppColors.borderCyan : AppColors.red;
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('내 상태', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Text('팀 선택', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Opacity(
            opacity: ready ? 0.6 : 1,
            child: IgnorePointer(
              ignoring: ready,
              child: NeonRadioGroup<Team>(
                value: team,
                onChanged: (t) => ref.read(roomProvider.notifier).setMyTeam(t),
                options: const [
                  NeonRadioOption(
                    value: Team.police,
                    label: '경찰',
                    color: AppColors.borderCyan,
                  ),
                  NeonRadioOption(
                    value: Team.thief,
                    label: '도둑',
                    color: AppColors.red,
                  ),
                ],
                height: 40,
                radius: 14,
              ),
            ),
          ),
          if (ready) ...[
            const SizedBox(height: 6),
            Text(
              'READY 해제 후 팀 변경 가능',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          _ReadyToggleButton(
            ready: ready,
            color: teamColor,
            onTap: () =>
                ref.read(roomProvider.notifier).setMyReady(!ready),
          ),
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

  Widget _lobbyActionBar(
    BuildContext context,
    WidgetRef ref, {
    required bool canStart,
    required double height,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface1.withOpacity(0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        border: Border.all(color: AppColors.outlineLow, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 42,
            child: OutlinedButton(
              onPressed: () {
                ref.read(roomProvider.notifier).leaveRoom();
                ref.read(gamePhaseProvider.notifier).toOffGame();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: const BorderSide(color: AppColors.outlineLow),
              ),
              child: const Text('나가기'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 58,
            child: GradientButton(
              key: const Key('lobbyStartButton'),
              variant: GradientButtonVariant.createRoom,
              title: '게임 시작',
              height: 44,
              borderRadius: 14,
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
    );
  }

  String _startNotice({
    required bool isHost,
    required int totalPlayers,
    required bool allReady,
    required bool teamOk,
  }) {
    if (!isHost) return '게임 시작은 방장만 가능합니다.';
    if (totalPlayers < 2) return '최소 2명 이상이어야 시작할 수 있습니다.';
    if (!teamOk) return '경찰/도둑 팀 수를 확인하세요.';
    if (!allReady) return '모든 멤버가 준비되어야 시작할 수 있습니다.';
    return '';
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

  const _MemberRow({
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    final teamIcon =
        member.team == Team.police ? Icons.shield_rounded : Icons.lock_rounded;
    final teamColor =
        member.team == Team.police ? AppColors.borderCyan : AppColors.red;
    final readyText = member.ready ? 'READY' : 'WAIT';

    return Row(
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
    );
  }
}

class _ReadyToggleButton extends StatelessWidget {
  final bool ready;
  final Color color;
  final VoidCallback onTap;

  const _ReadyToggleButton({
    required this.ready,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ready ? color.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ready ? color.withOpacity(0.8) : AppColors.outlineLow,
          ),
          boxShadow: ready
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          ready ? 'READY' : 'WAIT',
          style: TextStyle(
            color: ready ? color : AppColors.textMuted,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
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
