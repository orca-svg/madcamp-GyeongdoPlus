import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_bottom_bar.dart';
import '../radar/radar_screen.dart';
import '../stats/stats_screen.dart';
import '../ability/ability_screen.dart';
import '../match/match_screen.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/shell_tab_request_provider.dart';
import '../../providers/watch_provider.dart';
import '../../providers/match_mode_provider.dart';
import '../../net/ws/ws_client_provider.dart';
import '../../ui/history/history_screen.dart';
import '../../ui/lobby/lobby_screen.dart';
import '../../ui/post_game/post_game_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

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

  @override
  void initState() {
    super.initState();

    unawaited(ref.read(watchConnectedProvider.notifier).init());
    ref.read(wsRouterProvider);

    _phaseSub = ref.listenManual<GamePhase>(gamePhaseProvider, (prev, next) {
      if (!mounted) return;
      if (next == GamePhase.offGame) {
        ref.read(wsConnectionProvider.notifier).disconnect();
        final requested = ref.read(shellTabRequestProvider.notifier).consume();
        final safe = (requested != null && requested >= 0 && requested < _screensOff.length) ? requested : 0;
        setState(() => _index = safe);
      }
      if (next == GamePhase.inGame) setState(() => _index = 0); // 레이더가 기본 탭 (index 0)
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
        final tabConfig = ref.watch(inGameTabConfigProvider);
        final tabs = _buildInGameTabs(tabConfig);
        final screens = tabs.map((t) => t.screen).toList();
        return Stack(
          fit: StackFit.expand,
          children: [
            IndexedStack(index: _index.clamp(0, screens.length - 1), children: screens),
            Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomBarInGame(
                tabs: tabs,
                currentIndex: _index.clamp(0, screens.length - 1),
                onTap: (i) => setState(() => _index = i),
              ),
            ),
          ],
        );
    }
  }

  /// 모드에 따라 IN_GAME 탭 구성을 동적으로 생성
  List<InGameTabSpec> _buildInGameTabs(InGameTabConfig config) {
    return [
      const InGameTabSpec(
        icon: Icons.radar_rounded,
        label: '레이더',
        screen: RadarScreen(),
      ),
      if (config.showAbilityTab)
        const InGameTabSpec(
          icon: Icons.flash_on_rounded,
          label: '능력',
          screen: AbilityScreen(),
        ),
      if (config.showItemTab)
        const InGameTabSpec(
          icon: Icons.inventory_2_rounded,
          label: '아이템',
          screen: AbilityScreen(), // TODO: ItemScreen 구현 시 교체
        ),
      const InGameTabSpec(
        icon: Icons.map_rounded,
        label: '구역',
        screen: StatsScreen(),
      ),
      const InGameTabSpec(
        icon: Icons.settings_rounded,
        label: '설정',
        screen: MatchScreen(),
      ),
    ];
  }
}
