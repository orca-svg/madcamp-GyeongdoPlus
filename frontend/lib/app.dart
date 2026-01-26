import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'features/navigation/bottom_nav_shell.dart';
import 'features/auth/login_screen.dart';
import 'features/zone/zone_editor_screen.dart';

class GyeongdoPlusApp extends ConsumerWidget {
  const GyeongdoPlusApp({super.key});

  // Debug flag: run with --dart-define=DEBUG_START_ZONE_EDITOR=true
  static const _debugZoneEditor = bool.fromEnvironment('DEBUG_START_ZONE_EDITOR');
  static bool _prefsPinged = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!_prefsPinged) {
      _prefsPinged = true;
      Future.microtask(() async {
        try {
          await SharedPreferences.getInstance();
          debugPrint('[PREFS] ok');
        } catch (e) {
          debugPrint('[PREFS] error=$e');
        }
      });
    }
    return MaterialApp(
      title: '경도+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      builder: (context, child) => HeroControllerScope.none(child: child!),
      home: _debugZoneEditor
          ? const Scaffold(body: ZoneEditorScreen())
          : (!auth.initialized || auth.status == AuthStatus.signingIn)
              ? const Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Center(child: CircularProgressIndicator()),
                )
              : (auth.status == AuthStatus.signedOut)
                  ? const LoginScreen()
                  : const BottomNavShell(),
    );
  }
}
