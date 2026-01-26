import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NeonCard extends StatelessWidget {
  final Widget child;
  final Color neonColor;
  final double glowOpacity;
  final double glowBlur;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final double radius;

  const NeonCard({
    super.key,
    required this.child,
    required this.neonColor,
    this.glowOpacity = 0.24,
    this.glowBlur = 16,
    this.borderWidth = 1.5,
    this.padding = const EdgeInsets.all(12),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: neonColor.withOpacity(0.6), width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: neonColor.withOpacity(glowOpacity),
            blurRadius: glowBlur,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
