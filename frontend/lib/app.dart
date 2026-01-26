import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/bottom_nav_shell.dart';
import 'features/zone/zone_editor_screen.dart';

class GyeongdoPlusApp extends StatelessWidget {
  const GyeongdoPlusApp({super.key});

  // Debug flag: run with --dart-define=DEBUG_START_ZONE_EDITOR=true
  static const _debugZoneEditor = bool.fromEnvironment('DEBUG_START_ZONE_EDITOR');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GyeongdoPlus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: _debugZoneEditor
          ? const Scaffold(body: ZoneEditorScreen())
          : const BottomNavShell(),
    );
  }
}
