import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/watch_provider.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final me = room.me;
    final watchConnected = ref.watch(watchConnectedProvider);
    final allReady = room.allReady;
    final isHost = room.amIHost;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GlowCard(
                      glow: false,
                      borderColor: AppColors.outlineLow,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '환영합니다',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            me?.name ?? '김선수',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '시즌 12 • 다이아몬드 II',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: -8,
                      child: Transform.translate(
                        offset: const Offset(0, 8),
                        child: _watchIndicatorCompact(watchConnected),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlowCard(
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
                              },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GlowCard(
                    glow: false,
                    borderColor: AppColors.outlineLow,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '멤버',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: room.members.length,
                            separatorBuilder: (_, __) => const Divider(
                              color: AppColors.outlineLow,
                              height: 16,
                            ),
                            itemBuilder: (context, i) {
                              final m = room.members[i];
                              final isMe = m.id == room.myId;
                              return SizedBox(
                                height: 52,
                                child: _MemberRow(
                                  member: m,
                                  isMe: isMe,
                                  onToggleReady: isMe
                                      ? () => ref
                                            .read(roomProvider.notifier)
                                            .toggleReady()
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '팀 선택',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 10),
                        _TeamSelector(
                          team: me?.team ?? Team.police,
                          enabled: !(me?.ready ?? false),
                          onChanged: (t) =>
                              ref.read(roomProvider.notifier).setMyTeam(t),
                        ),
                      ],
                    ),
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
                        onPressed: (isHost && allReady)
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
}

class _MemberRow extends StatelessWidget {
  final RoomMember member;
  final bool isMe;
  final VoidCallback? onToggleReady;

  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.onToggleReady,
  });

  @override
  Widget build(BuildContext context) {
    final teamIcon =
        member.team == Team.police ? Icons.shield_rounded : Icons.lock_rounded;
    final teamColor =
        member.team == Team.police ? AppColors.borderCyan : AppColors.orange;
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
        if (isMe) ...[
          const SizedBox(width: 8),
          TextButton(
            key: const Key('lobbyReadyButton'),
            onPressed: onToggleReady,
            child: Text(member.ready ? '해제' : '준비'),
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
                  style: TextStyle(
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

Widget _watchIndicatorCompact(bool connected) {
  final color = connected ? AppColors.lime : AppColors.textMuted;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surface2.withOpacity(0.35),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.watch_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          connected ? 'Connected' : 'Off',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}
