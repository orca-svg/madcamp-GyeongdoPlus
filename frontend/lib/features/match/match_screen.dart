import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/ws_status_pill.dart';
import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../net/ws/dto/match_state.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/match_sync_provider.dart';
import '../../providers/room_provider.dart';
import '../../net/ws/ws_client_provider.dart';
import '../../providers/ws_ui_status_provider.dart';


class MatchScreen extends ConsumerWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final rules = ref.watch(matchRulesProvider);
    final sync = ref.watch(matchSyncProvider);
    final wsUi = ref.watch(wsUiStatusProvider);
    final isHost = room.amIHost;
    final lastState = sync.lastMatchState?.payload;

    if (lastState == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: GlassBackground(
          child: SafeArea(
            bottom: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, AppDimens.bottomBarHIn + 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('경기 설정', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  WsStatusPill(
                    model: wsUi,
                    onReconnect: wsUi.showReconnect ? () => ref.read(wsConnectionProvider.notifier).connect() : null,
                  ),
                  const SizedBox(height: 14),
                  _ServerSyncCard(
                    state: null,
                    matchId: sync.currentMatchId,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, AppDimens.bottomBarHIn + 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('경기 설정', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  '방장만 세부 항목을 설정할 수 있습니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                WsStatusPill(
                  model: wsUi,
                  onReconnect: wsUi.showReconnect ? () => ref.read(wsConnectionProvider.notifier).connect() : null,
                ),
                const SizedBox(height: 10),
                _ServerSyncCard(
                  state: lastState,
                  matchId: sync.currentMatchId ?? sync.lastMatchState?.payload.matchId,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SideCard(
                        title: '경찰',
                        value: '${room.policeCount}',
                        accent: AppColors.borderCyan,
                        icon: Icons.shield_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SideCard(
                        title: '도둑',
                        value: '${room.thiefCount}',
                        accent: AppColors.red,
                        icon: Icons.lock_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: Text('경기 규칙', style: Theme.of(context).textTheme.titleMedium)),
                    if (!isHost) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _RuleTile(
                  title: '경기 시간',
                  value: '${rules.durationMin}분',
                  accent: AppColors.borderCyan,
                  enabled: isHost,
                  onTap: isHost
                      ? () async {
                          final v = await _editInt(
                            context: context,
                            title: '경기 시간(분)',
                            initial: rules.durationMin,
                            min: 1,
                            max: 60,
                          );
                          if (v != null) ref.read(matchRulesProvider.notifier).setDurationMin(v);
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                _RuleTile(
                  title: '경기장',
                  value: rules.mapName,
                  accent: AppColors.borderCyan,
                  enabled: isHost,
                  onTap: isHost
                      ? () async {
                          final v = await _editText(
                            context: context,
                            title: '경기장',
                            hint: '예) 도심',
                            initial: rules.mapName,
                          );
                          if (v != null && v.trim().isNotEmpty) {
                            ref.read(matchRulesProvider.notifier).setMapName(v.trim());
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                _RuleTile(
                  title: '경기 참여 인원',
                  value: '최대 ${rules.maxPlayers}명',
                  accent: AppColors.borderCyan,
                  enabled: isHost,
                  onTap: isHost
                      ? () async {
                          final v = await _editInt(
                            context: context,
                            title: '최대 인원(명)',
                            initial: rules.maxPlayers,
                            min: 2,
                            max: 10,
                          );
                          if (v != null) ref.read(matchRulesProvider.notifier).setMaxPlayers(v);
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                _RuleTile(
                  title: '해방 방식',
                  value: rules.releaseMode,
                  accent: AppColors.borderCyan,
                  enabled: isHost,
                  onTap: isHost
                      ? () async {
                          final v = await _editReleaseMode(
                            context: context,
                            current: rules.releaseMode,
                          );
                          if (v != null) ref.read(matchRulesProvider.notifier).setReleaseMode(v);
                        }
                      : null,
                ),
                const SizedBox(height: 22),
                Text('테스트', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                GradientButton(
                  variant: GradientButtonVariant.joinRoom,
                  title: '경기 종료(테스트)',
                  onPressed: () => ref.read(gamePhaseProvider.notifier).toPostGame(),
                  leading: const Icon(Icons.flag_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _editText({
    required BuildContext context,
    required String title,
    required String hint,
    required String initial,
  }) {
    final controller = TextEditingController(text: initial);
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: _EditSheet(
            title: title,
            child: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface2.withOpacity(0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.outlineLow.withOpacity(0.9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.outlineLow.withOpacity(0.9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.borderCyan.withOpacity(0.8)),
                ),
              ),
            ),
            onSave: () => Navigator.of(context).pop(controller.text),
          ),
        );
      },
    );
  }

  Future<int?> _editInt({
    required BuildContext context,
    required String title,
    required int initial,
    required int min,
    required int max,
  }) {
    final controller = TextEditingController(text: '$initial');
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: _EditSheet(
            title: title,
            helper: '$min ~ $max',
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '$initial',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface2.withOpacity(0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.outlineLow.withOpacity(0.9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.outlineLow.withOpacity(0.9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.borderCyan.withOpacity(0.8)),
                ),
              ),
            ),
            onSave: () {
              final v = int.tryParse(controller.text.trim());
              if (v == null) return Navigator.of(context).pop(null);
              final clamped = v.clamp(min, max);
              Navigator.of(context).pop(clamped);
            },
          ),
        );
      },
    );
  }

  Future<String?> _editReleaseMode({required BuildContext context, required String current}) {
    final options = const ['터치/근접', '키 해제', '시간 해제'];
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        var selected = current;
        return StatefulBuilder(
          builder: (context, setState) {
            return _EditSheet(
              title: '해방 방식',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final o in options)
                    ChoiceChip(
                      selected: selected == o,
                      onSelected: (_) => setState(() => selected = o),
                      label: Text(o),
                      labelStyle: TextStyle(
                        color: selected == o ? Colors.black : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                      selectedColor: AppColors.borderCyan,
                      backgroundColor: AppColors.surface2.withOpacity(0.35),
                      side: BorderSide(color: AppColors.outlineLow.withOpacity(0.9)),
                    ),
                ],
              ),
              onSave: () => Navigator.of(context).pop(selected),
            );
          },
        );
      },
    );
  }
}

class _ServerSyncCard extends StatelessWidget {
  final MatchStateDto? state;
  final String? matchId;

  const _ServerSyncCard({
    required this.state,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s == null) {
      return GlowCard(
        glow: true,
        glowColor: AppColors.borderCyan.withOpacity(0.10),
        borderColor: AppColors.borderCyan.withOpacity(0.25),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.borderCyan),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '서버 동기화 대기 중…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            if (matchId != null && matchId!.isNotEmpty)
              Text(
                matchId!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
          ],
        ),
      );
    }

    final endsAt = s.time.endsAtMs;
    final remainText = (endsAt == null || s.time.serverNowMs == 0) ? '—' : _formatRemaining(s.time.serverNowMs, endsAt);

    final score = s.live.score;
    final cap = s.live.captureProgress?.progress01;
    final rescue = s.live.rescueProgress?.progress01;

    final capText = (cap == null) ? '—' : '${(cap * 100).round()}%';
    final rescueText = (rescue == null) ? '—' : '${(rescue * 100).round()}%';

    return GlowCard(
      glow: true,
      glowColor: AppColors.borderCyan.withOpacity(0.10),
      borderColor: AppColors.borderCyan.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: AppColors.lime, size: 18),
              const SizedBox(width: 8),
              Text('서버 스냅샷', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text(
                s.matchId,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MiniPill(label: 'state', value: s.state),
              _MiniPill(label: 'mode', value: s.mode),
              _MiniPill(label: '남은시간', value: remainText),
              if (score != null) _MiniPill(label: '도둑', value: '${score.thiefFree}F/${score.thiefCaptured}C'),
              _MiniPill(label: 'capture', value: capText),
              _MiniPill(label: 'rescue', value: rescueText),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final String value;

  const _MiniPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineLow.withOpacity(0.8)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          children: [
            TextSpan(text: '$label  '),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRemaining(int serverNowMs, int endsAtMs) {
  final remain = endsAtMs - serverNowMs;
  if (remain <= 0) return '0:00';
  final d = Duration(milliseconds: remain);
  final m = d.inMinutes;
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}


class _SideCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  const _SideCard({required this.title, required this.value, required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: accent.withOpacity(0.10),
      borderColor: accent.withOpacity(0.35),
      child: SizedBox(
        height: 96,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Text(value, style: TextStyle(color: accent, fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  final bool enabled;
  final VoidCallback? onTap;

  const _RuleTile({
    required this.title,
    required this.value,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.85;
    return Opacity(
      opacity: opacity,
      child: GlowCard(
        glow: false,
        borderColor: enabled ? accent.withOpacity(0.25) : AppColors.outlineLow,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusCard),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(value, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                if (!enabled) ...[
                  const SizedBox(width: 8),
                  const Text('READ ONLY', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  const Icon(Icons.lock_rounded, color: AppColors.textMuted),
                ] else ...[
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditSheet extends StatelessWidget {
  final String title;
  final String? helper;
  final Widget child;
  final VoidCallback onSave;

  const _EditSheet({required this.title, required this.child, required this.onSave, this.helper});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: GlowCard(
          glow: true,
          glowColor: AppColors.borderCyan.withOpacity(0.12),
          borderColor: AppColors.borderCyan.withOpacity(0.35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                  if (helper != null)
                    Text(
                      helper!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              child,
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientButton(
                      variant: GradientButtonVariant.createRoom,
                      title: '저장',
                      onPressed: onSave,
                      leading: const Icon(Icons.check_rounded, color: Colors.white),
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
}
