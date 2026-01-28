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
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';

import '../../providers/game_phase_provider.dart';

import '../../providers/room_provider.dart';
import '../../providers/match_rules_provider.dart';

import 'widgets/game_config_card.dart';
import 'widgets/mini_map_card.dart';
import 'widgets/ability_select_card.dart';
import '../../core/services/audio_service.dart'; // Audio

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    // Play Lobby BGM
    ref.read(audioServiceProvider).playBgm(AudioType.bgmLobby);
  }

  @override
  void dispose() {
    // Stop BGM when leaving lobby (e.g. to Game or Home)
    ref.read(audioServiceProvider).stopBgm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);

    final rules = ref.watch(matchRulesProvider);

    final me = room.me;
    final isHost = room.amIHost;
    final allReady = room.allReady;
    final totalPlayers = room.members.length;

    // Strict Team/Count Check
    final targetPolice = rules.policeCount;
    final targetThief = rules.maxPlayers - rules.policeCount;
    final actualPolice = room.policeCount;
    final actualThief = room.thiefCount;

    final countMatch =
        (actualPolice == targetPolice) && (actualThief == targetThief);
    final fullRoom = totalPlayers == rules.maxPlayers;

    // Logic: Must be full room & correct distribution (Team numbers match rules)
    final canStart = isHost && allReady && fullRoom && countMatch;

    final bottomBarHeight = 68.0;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomInset = bottomBarHeight + safeBottom + (isHost ? 32 : 28);

    final startNotice = _startNotice(
      isHost: isHost,
      allReady: allReady,
      fullRoom: fullRoom,
      countMatch: countMatch,
      targetPolice: targetPolice,
      targetThief: targetThief,
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
                  // Step 0: Room Code Card (New)
                  _RoomCodeCard(roomId: room.roomCode),
                  const SizedBox(height: 12),

                  // Step 1: Game Config Card
                  const GameConfigCard(),
                  const SizedBox(height: 12),

                  // Step 2: Ability Selection (Conditional)
                  if (rules.gameMode == GameMode.ability) ...[
                    const AbilitySelectCard(),
                    const SizedBox(height: 12),
                  ],

                  // Step 3: Members Card
                  _membersCard(context, room, me?.id),
                  const SizedBox(height: 12),
                  const MiniMapCard(),

                  if (kDebugMode) ...[
                    const SizedBox(height: 12),
                    _devBotCard(context),
                  ],
                ],
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (startNotice.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 8,
                          left: 18,
                          right: 18,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            startNotice,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    _lobbyActionBar(
                      context,
                      ref,
                      canStart: canStart,
                      safeBottom: safeBottom,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _roomInfoCard replaced by integrated header in _rulesSummaryCard

  Widget _membersCard(BuildContext context, RoomState room, String? myId) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '멤버 (${room.members.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Row(
                children: [
                  Icon(
                    Icons.shield_rounded,
                    size: 14,
                    color: AppColors.borderCyan,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.policeCount}',
                    style: const TextStyle(
                      color: AppColors.borderCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.lock_rounded, size: 14, color: AppColors.red),
                  const SizedBox(width: 4),
                  Text(
                    '${room.thiefCount}',
                    style: const TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (myId != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '내 카드를 탭하여 팀 변경',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: room.members.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.outlineLow, height: 16),
            itemBuilder: (context, i) {
              final m = room.members[i];
              final isMe = m.id == myId;
              return _InteractiveMemberRow(
                member: m,
                isMe: isMe,
                onRoleTap: isMe && !m.ready
                    ? () {
                        final newTeam = m.team == Team.police
                            ? Team.thief
                            : Team.police;
                        ref.read(roomProvider.notifier).setMyTeam(newTeam);
                      }
                    : null,
                onStatusTap: isMe
                    ? () {
                        ref.read(roomProvider.notifier).setMyReady(!m.ready);
                      }
                    : null,
              );
            },
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
    required double safeBottom,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18, safeBottom + 12),
      decoration: BoxDecoration(
        color: AppColors.surface1.withOpacity(0.95),
        border: const Border(top: BorderSide(color: AppColors.outlineLow)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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
                minimumSize: const Size.fromHeight(52),
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
              height: 52,
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
    required bool allReady,
    required bool fullRoom,
    required bool countMatch,
    required int targetPolice,
    required int targetThief,
  }) {
    if (!isHost) return '게임 시작은 방장만 가능합니다.';
    if (!fullRoom)
      return '설정된 인원(${(targetPolice + targetThief)}명)이 모두 입장해야 합니다.';
    if (!countMatch) return '경찰($targetPolice명)/도둑($targetThief명) 팀 배정을 맞춰주세요.';
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
}

class _InteractiveMemberRow extends StatelessWidget {
  final RoomMember member;
  final bool isMe;
  final VoidCallback? onRoleTap;
  final VoidCallback? onStatusTap;

  const _InteractiveMemberRow({
    required this.member,
    required this.isMe,
    this.onRoleTap,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final teamIcon = member.team == Team.police
        ? Icons.shield_rounded
        : Icons.lock_rounded;
    final teamColor = member.team == Team.police
        ? AppColors.borderCyan
        : AppColors.red;

    // Ready status style
    final isReady = member.ready;
    final statusColor = isReady ? AppColors.lime : Colors.grey;
    final statusText = isReady ? 'READY' : 'WAIT';

    return Container(
      decoration: isMe
          ? BoxDecoration(
              color: teamColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: teamColor.withOpacity(0.3)),
            )
          : null,
      padding: isMe
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
          : const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Role Icon (Tappable if me)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRoleTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(teamIcon, size: 20, color: teamColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and Host Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.w600,
                          fontSize: isMe ? 15 : 14,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '(나)',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                if (member.isHost)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'HOST',
                      style: TextStyle(
                        color: AppColors.borderCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Ready/Wait Button (Tappable if me)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onStatusTap,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isReady
                      ? statusColor.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isReady ? statusColor : AppColors.outlineLow,
                    width: isReady ? 1.5 : 1.0,
                  ),
                  boxShadow: isReady
                      ? [
                          BoxShadow(
                            color: statusColor.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: isReady ? statusColor : AppColors.textMuted,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCodeCard extends StatelessWidget {
  final String roomId;
  const _RoomCodeCard({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.qr_code_rounded, color: AppColors.textPrimary, size: 20),
          const SizedBox(width: 10),
          Text(
            '참여 코드',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              roomId
                  .toUpperCase(), // Display full code as received from backend
              style: const TextStyle(
                fontFamily: 'Monospace',
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: const Icon(
              Icons.copy_rounded,
              size: 18,
              color: AppColors.borderCyan,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: roomId));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('코드가 복사되었습니다.')));
            },
            tooltip: '코드 복사',
          ),
        ],
      ),
    );
  }
}
