import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bgTop, AppColors.bgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.55),
              radius: 1.2,
              colors: [
                Colors.white.withOpacity(0.06),
                Colors.black.withOpacity(0.52),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

