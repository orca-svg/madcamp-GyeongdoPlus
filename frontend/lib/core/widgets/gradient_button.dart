import 'package:flutter/material.dart';
import '../app_dimens.dart';
import '../theme/app_colors.dart';

enum GradientButtonVariant { createRoom, joinRoom }

class GradientButton extends StatefulWidget {
  final GradientButtonVariant variant;
  final String title;
  final VoidCallback? onPressed;
  final Widget? leading;
  final double height;
  final double borderRadius;

  const GradientButton({
    super.key,
    required this.variant,
    required this.title,
    required this.onPressed,
    this.leading,
    this.height = 68,
    this.borderRadius = AppDimens.radiusButton,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  Gradient get _gradient {
    switch (widget.variant) {
      case GradientButtonVariant.createRoom:
        return const LinearGradient(
          colors: [AppColors.borderCyan, AppColors.graphBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case GradientButtonVariant.joinRoom:
        return const LinearGradient(
          colors: [AppColors.orange, AppColors.graphYellow],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final scale = (_pressed && enabled) ? 0.985 : 1.0;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(_pressed ? 0.06 : 0.0),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leading != null) ...[
                        widget.leading!,
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
