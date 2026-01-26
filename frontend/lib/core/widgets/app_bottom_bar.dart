import 'dart:ui';
import 'package:flutter/material.dart';
import '../app_dimens.dart';
import '../theme/app_colors.dart';
import '../../providers/match_mode_provider.dart';

class AppBottomBarInGame extends StatelessWidget {
  final List<InGameTabSpec> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomBarInGame({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = tabs.map((t) => _BarItem(icon: t.icon, label: t.label)).toList();
    return _AppBottomBarBase(
      height: AppDimens.bottomBarHIn,
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}

class AppBottomBarOffGame extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomBarOffGame({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _BarItem(icon: Icons.home_rounded, label: '홈'),
      _BarItem(icon: Icons.bar_chart_rounded, label: '전적'),
      _BarItem(icon: Icons.person_rounded, label: '내정보'),
    ];
    return _AppBottomBarBase(
      height: AppDimens.bottomBarHOff,
      items: items,
      currentIndex: currentIndex,
      onTap: onTap,
    );
  }
}

class _AppBottomBarBase extends StatelessWidget {
  final double height;
  final List<_BarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppBottomBarBase({
    required this.height,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final totalHeight = (height + bottomInset).clamp(height, 72.0);
    final safeInset = (totalHeight - height).clamp(0.0, bottomInset);
    return SafeArea(
      top: false,
      bottom: false,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: totalHeight,
              decoration: BoxDecoration(
                color: AppColors.surface1.withOpacity(0.72),
                border: const Border(top: BorderSide(color: AppColors.outlineLow, width: 1)),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: safeInset),
                child: Row(
                  children: [
                    for (int i = 0; i < items.length; i++)
                      Expanded(
                        child: _BottomBarButton(
                          item: items[i],
                          selected: i == currentIndex,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final _BarItem item;
  final bool selected;
  final VoidCallback onTap;

  const _BottomBarButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.borderCyan : AppColors.textMuted;
    return InkResponse(
      onTap: onTap,
      radius: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (selected)
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.borderCyan.withOpacity(0.22),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                Icon(item.icon, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.1,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: selected ? 18 : 4,
              height: 2.4,
              decoration: BoxDecoration(
                color: selected ? AppColors.borderCyan : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarItem {
  final IconData icon;
  final String label;
  const _BarItem({required this.icon, required this.label});
}
