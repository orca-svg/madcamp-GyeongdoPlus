import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'match_rules_provider.dart';
import 'match_sync_provider.dart';

/// 현재 게임 모드 (서버 상태 우선, 없으면 로컬 규칙 fallback)
final currentGameModeProvider = Provider<GameMode>((ref) {
  final serverState = ref.watch(matchSyncProvider).lastMatchState?.payload;
  if (serverState != null && serverState.mode.isNotEmpty) {
    return GameMode.fromWire(serverState.mode);
  }
  return ref.watch(matchRulesProvider).gameMode;
});

/// IN_GAME 탭 구성 설정
class InGameTabConfig {
  final bool showAbilityTab;
  final bool showItemTab;

  const InGameTabConfig({
    required this.showAbilityTab,
    required this.showItemTab,
  });
}

/// 현재 게임 모드에 따른 탭 활성화 설정
final inGameTabConfigProvider = Provider<InGameTabConfig>((ref) {
  final mode = ref.watch(currentGameModeProvider);
  return InGameTabConfig(
    showAbilityTab: mode == GameMode.ability,
    showItemTab: mode == GameMode.item,
  );
});

/// 탭 정의 (아이콘, 라벨, 화면 빌더)
class InGameTabSpec {
  final IconData icon;
  final String label;
  final Widget screen;

  const InGameTabSpec({
    required this.icon,
    required this.label,
    required this.screen,
  });
}
