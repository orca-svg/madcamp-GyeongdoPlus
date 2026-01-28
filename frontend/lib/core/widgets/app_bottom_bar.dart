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
    final items = tabs
        .map((t) => _BarItem(icon: t.icon, label: t.label))
        .toList();
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

  const AppBottomBarOffGame({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _BarItem(icon: Icons.home_rounded, label: '홈'),
      _BarItem(icon: Icons.history_rounded, label: '전적'),
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
    final totalHeight = height + bottomInset;
    // Removed clamp which caused overflow.

    return SizedBox(
      height: totalHeight,
      // Use standard container instead of manual logic to handle SafeArea naturally if possible,
      // but here we want to paint background behind safe area too.
      // So we keep manual calculation but remove clamp.
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
                border: const Border(
                  top: BorderSide(color: AppColors.outlineLow, width: 1),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
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

  const _BottomBarButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.borderCyan : AppColors.textMuted;
    return InkResponse(
      onTap: onTap,
      radius: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4), // Reduced from 6
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (selected)
                  Container(
                    width: 28, // Reduced from 34
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.borderCyan.withOpacity(0.22),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                Icon(item.icon, color: color, size: 20), // Reduced from 22
              ],
            ),
            const SizedBox(height: 2), // Reduced from 3
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 10, // Reduced from 11
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.1,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2), // Reduced from 3
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: selected ? 16 : 4, // Reduced from 18
              height: 2,
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
