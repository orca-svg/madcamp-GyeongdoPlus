import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_dimens.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../models/game_config.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/match_rules_provider.dart' as rules;
import '../../../net/socket/socket_io_client_provider.dart';

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
        // 1. Update Room Config (Legacy)
        ref.read(roomProvider.notifier).updateConfig(result);

        // 2. Update Match Rules (Local)
        final rulesNotifier = ref.read(rules.matchRulesProvider.notifier);
        rulesNotifier.setGameMode(
          rules.GameMode.fromWire(result.gameMode.wireName),
        ); // match_rules uses its own enum
        rulesNotifier.setDurationMin(result.durationMin);
        rulesNotifier.setJailEnabled(result.jailEnabled);

        // 3. Emit Full Rules Sync for clients
        // We construct a payload similar to what applyOfflineRoomConfig expects
        final currentState = ref.read(rules.matchRulesProvider);
        final payload = {
          'mode': result.gameMode.wireName,
          'timeLimit': result.durationMin * 60,
          'rules': {
            'contactMode': currentState.contactMode,
            'jailRule': {
              'rescue': {
                'queuePolicy': currentState.rescueReleaseOrder,
                'releaseCount': currentState.rescueReleaseScope == 'PARTIAL'
                    ? 1
                    : 999,
              },
            },
          },
          'mapConfig': {
            'polygon': currentState.zonePolygon
                ?.map((p) => p.toJson())
                .toList(),
            'jail': {
              'lat': currentState.jailCenter?.lat,
              'lng': currentState.jailCenter?.lng,
              'radiusM': currentState.jailRadiusM,
            },
          },
        };

        ref
            .read(socketIoClientProvider.notifier)
            .emit('full_rules_update', payload);
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
        if (val != null) {
          setState(() => _config = _config.copyWith(gameMode: val));
        }
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
