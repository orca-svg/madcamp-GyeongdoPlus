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

import '../../features/zone/zone_editor_screen.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/match_rules_provider.dart' hide GameMode;
import '../../providers/room_provider.dart';
import '../../models/game_config.dart';
import '../../core/app_dimens.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
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
    final bottomInset = bottomBarHeight + safeBottom + (isHost ? 32 : 28);

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
                  // Step 1: Game Config Card
                  const GameConfigCard(),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),

                  // Step 3: Interactive Member List
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
                        canStart:
                            room.isGameStartable(rules.maxPlayers) && isHost,
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
              if (myId != null)
                Text(
                  '내 카드를 탭하여 변경',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
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

class GameConfigCard extends ConsumerWidget {
  const GameConfigCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final config = room.config ?? GameConfig.initial();
    final isHost = room.amIHost;

    return GlowCard(
      glow: true,
      glowColor: AppColors.glowCyan.withOpacity(0.3),
      borderColor: AppColors.borderCyan,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isHost ? () => _showEditDialog(context, ref, config) : null,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                _buildInfoItem(
                  context,
                  icon: Icons.sports_esports_rounded,
                  label: '모드',
                  value: config.gameMode.label,
                  highlight: true,
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  context,
                  icon: Icons.timer_rounded,
                  label: '제한 시간',
                  value: '${config.durationMin}분',
                  highlight: false,
                ),
                const SizedBox(width: 24),
                _buildInfoItem(
                  context,
                  icon: Icons.lock_open_rounded,
                  label: '감옥 해방',
                  value: config.jailEnabled ? '가능' : '불가',
                  highlight: false,
                ),
                if (isHost) ...[
                  const Spacer(),
                  const Icon(
                    Icons.edit_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool highlight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.borderCyan : AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            shadows: highlight
                ? [
                    BoxShadow(
                      color: AppColors.borderCyan.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    GameConfig current,
  ) {
    showDialog(
      context: context,
      builder: (context) => _ConfigDialog(initialConfig: current),
    ).then((result) {
      if (result is GameConfig) {
        ref.read(roomProvider.notifier).updateConfig(result);
      }
    });
  }
}

class _ConfigDialog extends StatefulWidget {
  final GameConfig initialConfig;

  const _ConfigDialog({required this.initialConfig});

  @override
  State<_ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<_ConfigDialog> {
  late GameConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineLow),
      ),
      title: const Text(
        '게임 설정',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDropdown(),
            const SizedBox(height: 20),
            _buildSlider(),
            const SizedBox(height: 20),
            _buildSwitch(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(color: AppColors.textMuted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.borderCyan,
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            Navigator.of(context).pop(_config);
          },
          child: const Text('적용'),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<GameMode>(
      value: _config.gameMode,
      dropdownColor: AppColors.surface2,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        labelText: '게임 모드',
        labelStyle: TextStyle(color: AppColors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineLow),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderCyan),
        ),
      ),
      items: GameMode.values.map((mode) {
        return DropdownMenuItem(value: mode, child: Text(mode.label));
      }).toList(),
      onChanged: (val) {
        if (val != null)
          setState(() => _config = _config.copyWith(gameMode: val));
      },
    );
  }

  Widget _buildSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '제한 시간: ${_config.durationMin}분',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Slider(
          value: _config.durationMin.toDouble(),
          min: 5,
          max: 60,
          divisions: 11, // 5, 10, ... 60
          label: '${_config.durationMin}분',
          activeColor: AppColors.borderCyan,
          inactiveColor: AppColors.outlineLow,
          onChanged: (val) {
            setState(
              () => _config = _config.copyWith(durationMin: val.round()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSwitch() {
    return SwitchListTile(
      title: const Text(
        '감옥 해방 가능',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ),
      value: _config.jailEnabled,
      activeColor: AppColors.borderCyan,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        setState(() => _config = _config.copyWith(jailEnabled: val));
      },
    );
  }
}

class MiniMapCard extends ConsumerWidget {
  const MiniMapCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.read(matchRulesProvider);
    final points = rules.zonePolygon ?? [];
    final jailCenter = rules.jailCenter;
    final jailRadius = rules.jailRadiusM;

    final polygon = points.length >= 3
        ? Polygon(
            polygonId: 'preview_poly',
            points: points.map((e) => LatLng(e.lat, e.lng)).toList(),
            strokeWidth: 2,
            strokeColor: AppColors.borderCyan,
            strokeOpacity: 0.8,
            fillColor: AppColors.borderCyan,
            fillOpacity: 0.1,
          )
        : null;

    final circle = (jailCenter != null && jailRadius != null)
        ? Circle(
            circleId: 'preview_jail',
            center: LatLng(jailCenter.lat, jailCenter.lng),
            radius: jailRadius,
            strokeWidth: 2,
            strokeColor: AppColors.purple,
            strokeOpacity: 0.8,
            fillColor: AppColors.purple,
            fillOpacity: 0.1,
          )
        : null;

    final center = _calcCenter(points, jailCenter);

    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            children: [
              IgnorePointer(
                child: KakaoMap(
                  center: center,
                  currentLevel: 5,
                  polygons: polygon != null ? [polygon] : null,
                  circles: circle != null ? [circle] : null,
                  zoomControl: false,
                  mapTypeControl: false,
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'MAP PREVIEW',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  LatLng _calcCenter(List<GeoPointDto> points, GeoPointDto? jail) {
    if (jail != null) return LatLng(jail.lat, jail.lng);
    if (points.isEmpty) return LatLng(37.5665, 126.9780);

    double latSum = 0;
    double lngSum = 0;
    for (var p in points) {
      latSum += p.lat;
      lngSum += p.lng;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }
}
