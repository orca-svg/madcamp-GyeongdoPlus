import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../net/ws/builders/ws_builders.dart';
import '../../net/ws/ws_client_provider.dart';
import '../../providers/match_sync_provider.dart';
import '../../providers/room_provider.dart';

class InGameCaptureScreen extends ConsumerStatefulWidget {
  const InGameCaptureScreen({super.key});

  @override
  ConsumerState<InGameCaptureScreen> createState() =>
      _InGameCaptureScreenState();
}

enum _CaptureTarget { nearest, select }

enum _CaptureReason { nfc, visual, other }

class _InGameCaptureScreenState extends ConsumerState<InGameCaptureScreen> {
  _CaptureTarget _target = _CaptureTarget.nearest;
  _CaptureReason _reason = _CaptureReason.nfc;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(matchSyncProvider);
    final room = ref.watch(roomProvider);
    final match = sync.lastMatchState?.payload;
    final capture = match?.live.captureProgress;
    final targetId = capture?.targetId;
    final allOk = capture?.allOk ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '체포',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '수동 체포는 서버 최종 판정입니다.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        allOk ? '체포 조건 충족' : '체포 조건 미충족',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: allOk ? AppColors.lime : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (kDebugMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.red.withOpacity(0.2),
                      child: const Text(
                        'DEBUG: 체포 조건 무시 가능',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Text('대상', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _SegmentRow(
                  value: _target,
                  items: const [
                    _SegmentItem(
                      value: _CaptureTarget.nearest,
                      label: '가장 가까운 적',
                    ),
                    _SegmentItem(
                      value: _CaptureTarget.select,
                      label: '플레이어 선택',
                    ),
                  ],
                  onChanged: (v) => setState(() => _target = v),
                  enabledMap: {_CaptureTarget.select: targetId != null},
                ),
                const SizedBox(height: 14),
                Text('사유', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _SegmentRow(
                  value: _reason,
                  items: const [
                    _SegmentItem(value: _CaptureReason.nfc, label: 'NFC 확인'),
                    _SegmentItem(value: _CaptureReason.visual, label: '현장 확인'),
                    _SegmentItem(value: _CaptureReason.other, label: '기타'),
                  ],
                  onChanged: (v) => setState(() => _reason = v),
                ),
                const Spacer(),
                GradientButton(
                  variant: GradientButtonVariant.joinRoom,
                  title: _loading ? '요청 중...' : '체포 확정 요청',
                  height: 48,
                  borderRadius: 14,
                  onPressed:
                      (_loading ||
                          (!kDebugMode && !allOk) ||
                          targetId == null ||
                          match == null ||
                          room.myId.isEmpty)
                      ? null
                      : () => _confirmCapture(
                          context: context,
                          matchId: match.matchId,
                          playerId: room.myId,
                          targetId: targetId,
                        ),
                  leading: const Icon(Icons.lock_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCapture({
    required BuildContext context,
    required String matchId,
    required String playerId,
    required String targetId,
  }) async {
    setState(() => _loading = true);
    final env = buildConfirmCapture(
      matchId: matchId,
      playerId: playerId,
      targetId: targetId,
      reason: _reason.name,
    );
    ref.read(wsClientProvider).sendEnvelope(env, (p) => p);
    if (context.mounted) {
      showAppSnackBar(context, message: '체포 요청 전송');
    }
    setState(() => _loading = false);
  }
}

class _SegmentRow<T> extends StatelessWidget {
  final T value;
  final List<_SegmentItem<T>> items;
  final ValueChanged<T> onChanged;
  final Map<T, bool>? enabledMap;

  const _SegmentRow({
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabledMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineLow),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _SegmentButton<T>(
                item: item,
                selected: item.value == value,
                enabled: enabledMap?[item.value] ?? true,
                onTap: () => onChanged(item.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentItem<T> {
  final T value;
  final String label;
  const _SegmentItem({required this.value, required this.label});
}

class _SegmentButton<T> extends StatelessWidget {
  final _SegmentItem<T> item;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.item,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.borderCyan : AppColors.textMuted;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.borderCyan.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: enabled ? color : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
