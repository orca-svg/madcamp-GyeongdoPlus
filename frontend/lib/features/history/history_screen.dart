import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../providers/room_provider.dart'; // For Team enum
import '../../providers/user_provider.dart';
import '../profile/widgets/history_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Fetch initial history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).fetchMatchHistory();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return; // Prevent multiple concurrent loads

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _isLoadingMore = true;
      ref.read(userProvider.notifier).loadMoreHistory().then((_) {
        if (mounted) {
          setState(() => _isLoadingMore = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final history = userState.matchHistory;
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '전적',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (userState.isLoading && history.isNotEmpty)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (userState.isLoading && history.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.borderCyan,
                        ),
                      );
                    }

                    if (userState.errorMessage != null && history.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '전적을 불러올 수 없습니다.',
                              style: TextStyle(
                                color: AppColors.red.withOpacity(0.8),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(userProvider.notifier)
                                    .fetchMatchHistory();
                              },
                              child: const Text('재시도'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (history.isEmpty) {
                      return const Center(
                        child: Text(
                          '아직 기록된 전적이 없습니다.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
                      itemCount:
                          history.length + (userState.hasMoreHistory ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == history.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final item = history[index];
                        final isWin = item.result == 'WIN';
                        final isPolice = item.role == 'POLICE';

                        return HistoryCard(
                          isWin: isWin,
                          teamType: isPolice ? Team.police : Team.thief,
                          scoreDelta: item
                              .myStat
                              .contribution, // Using contribution as score delta
                          date: _formatDate(item.gameInfo.playedAt),
                          resultText: isWin ? '승리' : '패배',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
