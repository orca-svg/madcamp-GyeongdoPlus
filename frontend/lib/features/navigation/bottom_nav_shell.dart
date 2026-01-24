import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bgTop, AppColors.bgBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: IndexedStack(index: _index, children: _screens),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.surface2.withOpacity(0.9),
            border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: AppColors.ally,
            unselectedItemColor: AppColors.textSecondary,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
              BottomNavigationBarItem(icon: Icon(Icons.radar_rounded), label: '레이더'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: '통계'),
              BottomNavigationBarItem(icon: Icon(Icons.flash_on_rounded), label: '능력'),
              BottomNavigationBarItem(icon: Icon(Icons.sports_esports_rounded), label: '매치'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: '프로필'),
            ],
          ),
        ),
      ),
    );
  }
}
