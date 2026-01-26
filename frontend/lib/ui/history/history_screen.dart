import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/delta_chip.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../providers/records_provider.dart';
import '../../features/history/record_model.dart';

enum _HistoryFilter { all, police, thief }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(recordsProvider);
    final filtered = switch (_filter) {
      _HistoryFilter.all => records,
      _HistoryFilter.police =>
        records.where((r) => r.myTeam.toUpperCase() == 'POLICE').toList(),
      _HistoryFilter.thief =>
        records.where((r) => r.myTeam.toUpperCase() == 'THIEF').toList(),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              18,
              14,
              18,
              AppDimens.bottomBarHOff + 12,
            ),
            itemCount: 4 + (filtered.isEmpty ? 1 : filtered.length),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text('전적', style: Theme.of(context).textTheme.titleLarge);
              }
              if (index == 1) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '최근 경기 기록',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }
              if (index == 2) {
                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _filterChip(
                        label: '전체',
                        selected: _filter == _HistoryFilter.all,
                        color: AppColors.borderCyan,
                        onTap: () => setState(() => _filter = _HistoryFilter.all),
                      ),
                      _filterChip(
                        label: '경찰',
                        selected: _filter == _HistoryFilter.police,
                        color: AppColors.borderCyan,
                        onTap: () =>
                            setState(() => _filter = _HistoryFilter.police),
                      ),
                      _filterChip(
                        label: '도둑',
                        selected: _filter == _HistoryFilter.thief,
                        color: AppColors.red,
                        onTap: () =>
                            setState(() => _filter = _HistoryFilter.thief),
                      ),
                    ],
                  ),
                );
              }

              if (index == 3) {
                return const SizedBox(height: 14);
              }

              final listIndex = index - 4;
              if (filtered.isEmpty) {
                return GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    '전적이 아직 없어요. 첫 게임을 시작해보세요!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              final r = filtered[listIndex];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _recordCard(context, r),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _recordCard(BuildContext context, RecordSummary r) {
    final isWin = r.result.toUpperCase() == 'WIN';
    final accent = isWin ? AppColors.lime : AppColors.red;
    final teamLabel = r.isPolice ? '경찰' : '도둑';

    return GlowCard(
      glow: true,
      glowColor: accent.withOpacity(0.12),
      borderColor: accent.withOpacity(0.35),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _pill(
                text: r.mode.toUpperCase(),
                border: AppColors.outlineLow,
                fill: AppColors.surface2.withOpacity(0.35),
                textColor: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '내 팀: $teamLabel',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _pill(
                        text: isWin ? '승리' : '패배',
                        border: accent.withOpacity(0.55),
                        fill: accent.withOpacity(0.12),
                        textColor: accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DeltaChip(delta: r.ratingDelta.toDouble()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            r.isPolice
                ? '체포 ${r.capturesOrRescues}명 · 이동거리 ${_fmtKm(r.distanceM)}'
                : '구출 ${r.capturesOrRescues}명 · 이동거리 ${_fmtKm(r.distanceM)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _fmtDate(r.playedAt),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _fmtDuration(r.durationSec),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
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
          border: Border.all(
            color: selected ? color : color.withOpacity(0.35),
            width: AppDimens.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.4,
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
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  String _fmtDuration(int sec) {
    final s = sec.clamp(0, 24 * 3600);
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _fmtKm(int meters) => '${(meters / 1000).toStringAsFixed(1)} km';
}
