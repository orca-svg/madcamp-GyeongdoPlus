import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatRing extends StatelessWidget {
  final double value01;
  final String label;

  const StatRing({super.key, required this.value01, required this.label});

  Color get _color {
    if (value01 < 0.5) return AppColors.red;
    if (value01 >= 0.8) return AppColors.lime;
    return AppColors.borderCyan;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (value01 * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 86,
          height: 86,
          child: CustomPaint(
            painter: _RingPainter(value01: value01, color: _color),
            child: Center(
              child: Text(
                '$pct%',
                style: TextStyle(
                  color: _color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value01;
  final Color color;

  _RingPainter({required this.value01, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2;
    final stroke = 7.0;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = AppColors.outlineLow.withOpacity(0.9);

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.85), color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: c, radius: r));

    canvas.drawArc(Rect.fromCircle(center: c, radius: r - stroke / 2), -pi / 2, 2 * pi, false, bg);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r - stroke / 2), -pi / 2, 2 * pi * value01, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.value01 != value01 || oldDelegate.color != color;
  }
}

