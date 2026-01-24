import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/bottom_nav_shell.dart';

class GyeongdoPlusApp extends StatelessWidget {
  const GyeongdoPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GyeongdoPlus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const BottomNavShell(),
    );
  }
}
