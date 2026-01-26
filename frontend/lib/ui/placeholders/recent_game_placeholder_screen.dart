import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../features/history/match_history_model.dart';
import '../../providers/match_history_provider.dart';

class RecentGamePlaceholderScreen extends ConsumerWidget {
  const RecentGamePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(matchHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('전적', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  '최근 경기 기록',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: items.isEmpty
                      ? _emptyCard(context)
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _historyCard(context, items[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    return Center(
      child: GlowCard(
        glow: false,
        borderColor: AppColors.outlineLow,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            '전적이 아직 없어요. 첫 게임을 시작해보세요!',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _historyCard(BuildContext context, MatchHistoryItem item) {
    final isPolice = item.myTeam == 'POLICE';
    final isWin = item.result == 'WIN';
    final accent = isWin ? AppColors.lime : AppColors.red;
    final modeColor = AppColors.purple.withOpacity(0.7);
    final modeLabel = item.mode;
    final teamLabel = isPolice ? '경찰' : '도둑';
    final mainStatLabel = isPolice ? '체포' : '해방';

    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _modeTag(modeLabel, modeColor),
              const SizedBox(width: 8),
              _chip('내 팀: $teamLabel'),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _resultBadge(isWin: isWin, accent: accent),
                  const SizedBox(height: 6),
                  Text(
                    _fmtDelta(item.ratingDelta),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$mainStatLabel ${item.capturesOrRescues} · 이동거리 ${_fmtKm(item.distanceM)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _fmtDate(item.playedAt),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const Spacer(),
              Text(
                _fmtDuration(item.durationSec),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineLow),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _resultBadge({required bool isWin, required Color accent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.7)),
      ),
      child: Text(
        isWin ? '승리' : '패배',
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtKm(int meters) => '${(meters / 1000).toStringAsFixed(1)} km';

  String _fmtDelta(int delta) =>
      delta >= 0 ? '+$delta' : delta.toString();
}
