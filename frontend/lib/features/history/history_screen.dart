import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../data/history_repository.dart';
import '../../providers/room_provider.dart'; // For Team enum
import '../profile/widgets/history_card.dart';

final historyListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(historyRepositoryProvider).fetchHistory();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyListProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom + 80;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GlassBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Text(
                  '전적',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Expanded(
                child: historyAsync.when(
                  data: (history) {
                    if (history.isEmpty) {
                      return const Center(
                        child: Text(
                          '아직 기록된 전적이 없습니다.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return HistoryCard(
                          isWin: item['isWin'] ?? false,
                          teamType: (item['team'] == 'POLICE')
                              ? Team.police
                              : Team.thief,
                          scoreDelta: item['scoreDelta'] ?? 0,
                          date: item['date'] ?? '',
                          resultText: item['result'] ?? '',
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.borderCyan,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      '전적을 불러올 수 없습니다.',
                      style: TextStyle(color: AppColors.red.withOpacity(0.8)),
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
}
