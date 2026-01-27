import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_bottom_bar.dart';
import '../../providers/active_tab_provider.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/match_mode_provider.dart';
import '../../providers/shell_tab_request_provider.dart';
import '../../providers/watch_provider.dart';
import '../../net/ws/ws_client_provider.dart';
import '../../net/socket/socket_io_router.dart';
import '../../watch/watch_action_handler.dart';
import '../../ui/lobby/lobby_screen.dart';
import '../../ui/post_game/post_game_screen.dart';
import '../home/home_screen.dart';
import '../ingame/ingame_capture_screen.dart';
import '../ingame/ingame_map_screen.dart';
import '../ingame/ingame_settings_placeholder_screen.dart';
import '../radar/radar_screen.dart';
import '../../features/profile/profile_screen.dart';

class BottomNavShell extends ConsumerStatefulWidget {
  const BottomNavShell({super.key});

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  int _index = 0; // 로컬 UI 상태 (activeTabProvider와 동기화됨)
  late final ProviderSubscription<GamePhase> _phaseSub;
  late final ProviderSubscription<ActiveTab> _tabSub;

  static const _screensOff = [HomeScreen(), ProfileScreen()];

  @override
  void initState() {
    super.initState();

    unawaited(ref.read(watchConnectedProvider.notifier).init());
    ref.read(wsRouterProvider);
    ref.read(socketIoRouterProvider); // Initialize Socket.IO router
    ref.read(
      watchActionHandlerInitProvider,
    ); // Start listening for WATCH_ACTION

    // Phase 변경 시 기본 탭으로 리셋
    _phaseSub = ref.listenManual<GamePhase>(gamePhaseProvider, (prev, next) {
      if (!mounted) return;
      if (next == GamePhase.offGame) {
        ref.read(wsConnectionProvider.notifier).disconnect();
        final requested = ref.read(shellTabRequestProvider.notifier).consume();
        if (requested != null &&
            requested >= 0 &&
            requested < _screensOff.length) {
          ref
              .read(activeTabProvider.notifier)
              .setFromPhaseAndIndex(next, requested);
        } else {
          ref.read(activeTabProvider.notifier).resetToPhaseDefault(next);
        }
      } else {
        // 다른 phase로 전환 시 기본 탭으로 리셋
        ref.read(activeTabProvider.notifier).resetToPhaseDefault(next);
      }
    });

    // activeTab 변경 시 로컬 _index 동기화
    _tabSub = ref.listenManual<ActiveTab>(activeTabProvider, (prev, next) {
      if (!mounted) return;
      final phase = ref.read(gamePhaseProvider);
      if (next.phase == phase) {
        setState(() => _index = next.indexInPhase);
      }
    });
  }

  @override
  void dispose() {
    _phaseSub.close();
    _tabSub.close();
    super.dispose();
  }

  void _onTabTap(int index) {
    final phase = ref.read(gamePhaseProvider);
    ref.read(activeTabProvider.notifier).setFromPhaseAndIndex(phase, index);
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
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            // If not on home tab (index 0), go back to home
            if (_index != 0) {
              _onTabTap(0);
            }
            // If on home tab, do nothing (prevent app exit)
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              IndexedStack(
                index: _index.clamp(0, _screensOff.length - 1),
                children: _screensOff,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AppBottomBarOffGame(
                  currentIndex: _index.clamp(0, _screensOff.length - 1),
                  onTap: _onTabTap,
                ),
              ),
            ],
          ),
        );
      case GamePhase.inGame:
        final List<InGameTabSpec> tabs = _buildInGameTabs();
        final screens = tabs.map((t) => t.screen).toList();
        return Stack(
          fit: StackFit.expand,
          children: [
            IndexedStack(
              index: _index.clamp(0, screens.length - 1),
              children: screens,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomBarInGame(
                tabs: tabs,
                currentIndex: _index.clamp(0, screens.length - 1),
                onTap: _onTabTap,
              ),
            ),
          ],
        );
    }
  }

  /// 모드에 따라 IN_GAME 탭 구성을 동적으로 생성
  List<InGameTabSpec> _buildInGameTabs() {
    return [
      InGameTabSpec(
        icon: Icons.sports_esports_rounded,
        label: '게임',
        screen: RadarScreen(),
      ),
      InGameTabSpec(
        icon: Icons.map_rounded,
        label: '지도',
        screen: InGameMapScreen(),
      ),
      InGameTabSpec(
        icon: Icons.lock_rounded,
        label: '체포',
        screen: InGameCaptureScreen(),
      ),
      InGameTabSpec(
        icon: Icons.settings_rounded,
        label: '설정',
        screen: InGameSettingsPlaceholderScreen(),
      ),
    ];
  }
}
