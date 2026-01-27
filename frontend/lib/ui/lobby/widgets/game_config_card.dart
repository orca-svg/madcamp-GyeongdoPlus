import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_dimens.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_card.dart';

import '../../../providers/room_provider.dart';
import '../../../providers/match_rules_provider.dart' as rules;
import '../../../net/socket/socket_io_client_provider.dart';

class GameConfigCard extends ConsumerWidget {
  const GameConfigCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final rulesState = ref.watch(rules.matchRulesProvider);
    final isHost = room.amIHost;

    // Derived values
    final pCount = rulesState.policeCount;
    final maxP = rulesState.maxPlayers;
    final tCount = maxP - pCount;
    final ratio = (maxP > 0) ? (pCount / maxP) : 0.0;

    // Formatting
    final contactLabel = rulesState.contactMode == 'CONTACT' ? '접촉' : '비접촉';
    final releaseScopeLabel = rulesState.rescueReleaseScope == 'PARTIAL'
        ? '일부'
        : '전체';
    final releaseOrderLabel = rulesState.rescueReleaseOrder == 'FIFO'
        ? '선착순'
        : '후착순';

    return GlowCard(
      glow: true,
      glowColor: AppColors.glowCyan.withOpacity(0.3),
      borderColor: AppColors.borderCyan,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isHost
              ? () => _showEditDialog(context, ref, rulesState)
              : null,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '경기 규칙',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (isHost)
                      const Icon(
                        Icons.edit_rounded,
                        color: AppColors.textMuted,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRow(
                  context,
                  '모드',
                  rulesState.gameMode.label,
                  Icons.sports_esports_rounded,
                  highlight: true,
                ),
                const SizedBox(height: 8),
                _buildRow(
                  context,
                  '인원 / 시간',
                  '$maxP명 / ${rulesState.durationMin}분',
                  Icons.timer_rounded,
                ),
                const SizedBox(height: 8),
                _buildRow(
                  context,
                  '경찰 비율',
                  '${(ratio * 100).round()}% (경찰 $pCount vs 도둑 $tCount)',
                  Icons.people_alt_rounded,
                ),
                const SizedBox(height: 8),
                _buildRow(
                  context,
                  '접촉 여부',
                  contactLabel,
                  Icons.call_missed_outgoing_rounded,
                ),
                const SizedBox(height: 8),
                if (rulesState.jailEnabled)
                  _buildRow(
                    context,
                    '해방 규칙',
                    '$releaseScopeLabel · $releaseOrderLabel',
                    Icons.lock_open_rounded,
                  ),
                if (!rulesState.jailEnabled)
                  _buildRow(context, '감옥 해방', '불가', Icons.lock_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.borderCyan : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    rules.MatchRulesState currentState,
  ) {
    showDialog(
      context: context,
      builder: (context) => _ConfigDialog(initialState: currentState),
    ).then((result) {
      if (result is rules.MatchRulesState) {
        // 1. Update Match Rules (Local)
        final rulesNotifier = ref.read(rules.matchRulesProvider.notifier);
        rulesNotifier.setGameMode(result.gameMode);
        rulesNotifier.setTimeLimitSec(result.timeLimitSec);
        rulesNotifier.setMaxPlayers(result.maxPlayers);
        rulesNotifier.setPoliceCount(result.policeCount);
        rulesNotifier.setContactMode(result.contactMode);
        // Helper method for release settings?
        // We might need to manually apply logic if not exposed getters.
        // Actually MatchRulesState has them.
        // But the notifier methods are setReleaseMode (string), setContactMode..
        // Logic for complex state update isn't 1:1 with setters.
        // Easiest is to generate payload and applyOfflineRoomConfig.

        // Construct payload
        final payload = {
          'mode': result.gameMode.wire,
          'maxPlayers': result.maxPlayers,
          'timeLimit': result.timeLimitSec,
          'rules': {
            'contactMode': result.contactMode,
            'jailRule': {
              'rescue': {
                'queuePolicy': result.rescueReleaseOrder,
                'releaseCount': result.rescueReleaseScope == 'PARTIAL'
                    ? 1
                    : 999,
              },
            },
          },
          // Preserve Map Config
          'mapConfig': {
            'polygon': result.zonePolygon?.map((p) => p.toJson()).toList(),
            'jail': result.jailCenter != null
                ? {
                    'lat': result.jailCenter!.lat,
                    'lng': result.jailCenter!.lng,
                    'radiusM': result.jailRadiusM,
                  }
                : null,
          },
        };

        rulesNotifier.applyOfflineRoomConfig(payload);

        // 2. Emit Settings Update to Server
        // As per request: socket.emit('update_settings', newSettings)
        ref
            .read(socketIoClientProvider.notifier)
            .emit('update_settings', payload);
      }
    });
  }
}

class _ConfigDialog extends StatefulWidget {
  final rules.MatchRulesState initialState;

  const _ConfigDialog({required this.initialState});

  @override
  State<_ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<_ConfigDialog> {
  late rules.MatchRulesState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  // Helpers
  void _update(rules.MatchRulesState newState) =>
      setState(() => _state = newState);

  @override
  Widget build(BuildContext context) {
    // Calculate Ratio for slider
    final ratio = (_state.maxPlayers > 0)
        ? (_state.policeCount / _state.maxPlayers)
        : 0.0;

    return AlertDialog(
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outlineLow),
      ),
      title: const Text(
        '게임 설정 편집',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section('게임 모드'),
              Wrap(
                spacing: 8,
                children: rules.GameMode.values
                    .map(
                      (m) => ChoiceChip(
                        label: Text(m.label),
                        selected: _state.gameMode == m,
                        onSelected: (sel) {
                          if (sel) _update(_state.copyWith(gameMode: m));
                        },
                        selectedColor: AppColors.borderCyan.withOpacity(0.3),
                        backgroundColor: AppColors.surface2,
                        labelStyle: TextStyle(
                          color: _state.gameMode == m
                              ? AppColors.borderCyan
                              : AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                        side: BorderSide(
                          color: _state.gameMode == m
                              ? AppColors.borderCyan
                              : AppColors.outlineLow,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              _section('인원: ${_state.maxPlayers}명'),
              Slider(
                min: 3,
                max: 50,
                divisions: 47,
                value: _state.maxPlayers.toDouble(),
                activeColor: AppColors.borderCyan,
                inactiveColor: AppColors.outlineLow,
                onChanged: (v) {
                  // Logic to auto-adjust police count needed?
                  // MatchRulesController has logic, but we are local.
                  // Simple logic: keep ratio.
                  final mp = v.round();
                  final pc = (mp * 0.4).round().clamp(
                    1,
                    mp - 1,
                  ); // fallback 40%
                  _update(_state.copyWith(maxPlayers: mp, policeCount: pc));
                },
              ),

              _section('경찰 비율: ${(ratio * 100).round()}%'),
              Slider(
                min: 0.1,
                max: 0.5,
                divisions: 4,
                value: ratio.clamp(0.1, 0.5), // safety
                activeColor: AppColors.borderCyan,
                inactiveColor: AppColors.outlineLow,
                onChanged: (v) {
                  final pc = (_state.maxPlayers * v).round().clamp(
                    1,
                    _state.maxPlayers - 1,
                  );
                  _update(
                    _state.copyWith(
                      policeCount: pc,
                      policeCountCustomized: true,
                    ),
                  );
                },
              ),
              Text(
                '경찰 ${_state.policeCount}명 vs 도둑 ${_state.maxPlayers - _state.policeCount}명',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 16),
              _section('시간: ${_state.durationMin}분'),
              Slider(
                min: 300,
                max: 1800,
                divisions: 25,
                value: _state.timeLimitSec.toDouble(),
                activeColor: AppColors.borderCyan,
                inactiveColor: AppColors.outlineLow,
                onChanged: (v) {
                  final s = v.round();
                  _update(
                    _state.copyWith(
                      timeLimitSec: s,
                      durationMin: (s / 60).round(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              _section('접촉 설정'),
              Row(
                children: [
                  _chip(
                    '비접촉',
                    _state.contactMode == 'NON_CONTACT',
                    () => _update(_state.copyWith(contactMode: 'NON_CONTACT')),
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    '접촉',
                    _state.contactMode == 'CONTACT',
                    () => _update(_state.copyWith(contactMode: 'CONTACT')),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _section('해방 범위'),
              Row(
                children: [
                  _chip(
                    '일부',
                    _state.rescueReleaseScope == 'PARTIAL',
                    () =>
                        _update(_state.copyWith(rescueReleaseScope: 'PARTIAL')),
                  ),
                  const SizedBox(width: 8),
                  _chip(
                    '전체',
                    _state.rescueReleaseScope == 'ALL',
                    () => _update(_state.copyWith(rescueReleaseScope: 'ALL')),
                  ),
                ],
              ),
              if (_state.rescueReleaseScope == 'PARTIAL') ...[
                const SizedBox(height: 12),
                _section('해방 순서'),
                Row(
                  children: [
                    _chip(
                      '선착순',
                      _state.rescueReleaseOrder == 'FIFO',
                      () =>
                          _update(_state.copyWith(rescueReleaseOrder: 'FIFO')),
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      '후착순',
                      _state.rescueReleaseOrder == 'LIFO',
                      () =>
                          _update(_state.copyWith(rescueReleaseOrder: 'LIFO')),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
          onPressed: () => Navigator.of(context).pop(_state),
          child: const Text('적용'),
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _chip(String label, bool sel, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel
              ? AppColors.borderCyan.withOpacity(0.2)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel ? AppColors.borderCyan : AppColors.outlineLow,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? AppColors.borderCyan : AppColors.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
