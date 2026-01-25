import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/match_sync_provider.dart';
import '../../providers/room_provider.dart';
import '../../net/ws/ws_client_provider.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final me = room.me;

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
                      icon: const Icon(Icons.exit_to_app_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _RoomCodeCard(
                  roomCode: room.roomCode,
                  onCopy: room.roomCode.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: room.roomCode));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('방 코드가 복사되었습니다')));
                        },
                ),
                const SizedBox(height: 16),
                Text('참가자', style: Theme.of(context).textTheme.titleMedium),
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
                            child: Divider(color: AppColors.outlineLow, height: 1),
                          ),
                          itemBuilder: (context, i) {
                            final m = room.members[i];
                            return _MemberRow(
                              member: m,
                              isMe: m.id == room.myId,
                              onTeamSelected: m.id == room.myId ? (t) => ref.read(roomProvider.notifier).setMyTeam(t) : null,
                            );
                          },
                        )
                      : _EmptyRoomCard(
                          onGoHome: () => ref.read(gamePhaseProvider.notifier).toOffGame(),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  '방장만 경기 규칙을 변경할 수 있습니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        variant: GradientButtonVariant.joinRoom,
                        title: (me?.ready ?? false) ? '준비 해제' : '준비 완료',
                        onPressed: room.inRoom ? () => ref.read(roomProvider.notifier).toggleReady() : null,
                        leading: Icon(
                          (me?.ready ?? false) ? Icons.undo_rounded : Icons.check_circle_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        variant: GradientButtonVariant.createRoom,
                        title: '경기 시작',
                        onPressed: (room.amIHost && room.allReady)
                            ? () {
                                final matchId = room.roomCode.isEmpty ? '' : 'm_${room.roomCode}';
                                if (matchId.isNotEmpty) {
                                  ref.read(matchSyncProvider.notifier).setCurrentMatchId(matchId);
                                  ref.read(wsConnectionProvider.notifier).connect();
                                  ref
                                      .read(wsConnectionProvider.notifier)
                                      .sendJoinMatch(matchId: matchId, playerId: room.myId, roomCode: room.roomCode);
                                }
                                ref.read(gamePhaseProvider.notifier).toInGame();
                              }
                            : null,
                        leading: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
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
                        onPressed: room.inRoom ? () => ref.read(roomProvider.notifier).addFakeMember() : null,
                        style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                        child: const Text('+ 봇 추가'),
                      ),
                      TextButton(
                        onPressed: room.inRoom ? () => ref.read(roomProvider.notifier).toggleFakeReadyAll() : null,
                        style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
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
            child: const Icon(Icons.vpn_key_rounded, color: AppColors.borderCyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('방 코드', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
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
            icon: const Icon(Icons.copy_rounded, color: AppColors.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final RoomMember member;
  final bool isMe;
  final ValueChanged<Team>? onTeamSelected;

  const _MemberRow({required this.member, required this.isMe, required this.onTeamSelected});

  @override
  Widget build(BuildContext context) {
    final teamLabel = member.team == Team.police ? '경찰' : '도둑';
    final teamColor = member.team == Team.police ? AppColors.borderCyan : AppColors.red;
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
            member.team == Team.police ? Icons.shield_rounded : Icons.lock_rounded,
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
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (member.isHost) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.emoji_events_rounded, size: 16, color: AppColors.orange),
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
          border: Border.all(color: selected ? color : color.withOpacity(0.35), width: AppDimens.border),
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
        style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.4),
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
        Expanded(child: Text(msg, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted))),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
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
