import 'package:flutter/material.dart';
import '../app_dimens.dart';
import '../theme/app_colors.dart';

class GlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? glowColor;
  final bool glow;
  final bool gradientSurface;

  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimens.padding16),
    this.borderColor,
    this.glowColor,
    this.glow = true,
    this.gradientSurface = true,
  });

  @override
  Widget build(BuildContext context) {
    final bc = borderColor ?? AppColors.borderCyan;
    final gc = glowColor ?? AppColors.glowCyan;

    return Container(
      decoration: BoxDecoration(
        gradient: gradientSurface
            ? const LinearGradient(
                colors: [AppColors.surface2, AppColors.surface1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: gradientSurface ? null : AppColors.surface1,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: bc.withOpacity(0.85), width: AppDimens.border),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: gc.withOpacity(AppDimens.glowOpacity),
                  blurRadius: AppDimens.glowBlur,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: AppDimens.shadowBlur,
                  offset: const Offset(0, 18),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: AppDimens.shadowBlur,
                  offset: const Offset(0, 18),
                ),
              ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
