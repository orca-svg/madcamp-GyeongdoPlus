import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_bottom_bar.dart';
import '../home/home_screen.dart';
import '../radar/radar_screen.dart';
import '../stats/stats_screen.dart';
import '../ability/ability_screen.dart';
import '../match/match_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/shell_tab_request_provider.dart';
import '../../providers/watch_provider.dart';
import '../../ui/history/history_screen.dart';
import '../../ui/lobby/lobby_screen.dart';
import '../../ui/post_game/post_game_screen.dart';

class BottomNavShell extends ConsumerStatefulWidget {
  const BottomNavShell({super.key});

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  int _index = 0; // OFF_GAME 기본 홈
  late final ProviderSubscription<GamePhase> _phaseSub;

  static const _screensOff = [
    HomeScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  static const _screensIn = [
    HomeScreen(),
    RadarScreen(),
    StatsScreen(),
    AbilityScreen(),
    MatchScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    unawaited(ref.read(watchConnectedProvider.notifier).init());

    _phaseSub = ref.listenManual<GamePhase>(gamePhaseProvider, (prev, next) {
      if (!mounted) return;
      if (next == GamePhase.offGame) {
        final requested = ref.read(shellTabRequestProvider.notifier).consume();
        final safe = (requested != null && requested >= 0 && requested < _screensOff.length) ? requested : 0;
        setState(() => _index = safe);
      }
      if (next == GamePhase.inGame) setState(() => _index = 1);
    });
  }

  @override
  void dispose() {
    _phaseSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(gamePhaseProvider);

    switch (phase) {
      case GamePhase.lobby:
        return const LobbyScreen();
      case GamePhase.postGame:
        return const PostGameScreen();
      case GamePhase.offGame:
        return Stack(
          fit: StackFit.expand,
          children: [
            IndexedStack(index: _index.clamp(0, _screensOff.length - 1), children: _screensOff),
            Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomBarOffGame(
                currentIndex: _index.clamp(0, _screensOff.length - 1),
                onTap: (i) => setState(() => _index = i),
              ),
            ),
          ],
        );
      case GamePhase.inGame:
        return Stack(
          fit: StackFit.expand,
          children: [
            IndexedStack(index: _index.clamp(0, _screensIn.length - 1), children: _screensIn),
            Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomBarInGame(
                currentIndex: _index.clamp(0, _screensIn.length - 1),
                onTap: (i) => setState(() => _index = i),
              ),
            ),
          ],
        );
    }
  }
}
