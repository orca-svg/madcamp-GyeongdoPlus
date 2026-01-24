import 'package:flutter/material.dart';
import '../../core/widgets/app_bottom_bar.dart';
import '../home/home_screen.dart';
import '../radar/radar_screen.dart';
import '../stats/stats_screen.dart';
import '../ability/ability_screen.dart';
import '../match/match_screen.dart';
import '../profile/profile_screen.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _index = 1; // 레이더가 메인처럼 보이게 기본 선택

  final _screens = const [
    HomeScreen(),
    RadarScreen(),
    StatsScreen(),
    AbilityScreen(),
    MatchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IndexedStack(index: _index, children: _screens),
        Align(
          alignment: Alignment.bottomCenter,
          child: AppBottomBarInGame(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
          ),
        ),
      ],
    );
  }
}
