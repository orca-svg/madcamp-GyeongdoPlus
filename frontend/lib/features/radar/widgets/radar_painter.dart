import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/radar_provider.dart';

class RadarPainter extends CustomPainter {
  final double sweep01; // 0..1
  final List<RadarPing> pings;

  RadarPainter({required this.sweep01, required this.pings});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2;

    // Outer ring base
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.ally.withOpacity(0.35)
      ..strokeWidth = 2;

    // Inner rings
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(c, r * (i / 5), ringPaint..color = AppColors.ally.withOpacity(0.22));
    }
    canvas.drawCircle(c, r * 0.98, Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.ally.withOpacity(0.35)
      ..strokeWidth = 2);

    // Cross lines
    final crossPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.ally.withOpacity(0.25)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), crossPaint);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), crossPaint);

    // Center dot
    canvas.drawCircle(c, 6, Paint()..color = AppColors.ally.withOpacity(0.9));
    canvas.drawCircle(c, 14, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.ally.withOpacity(0.35));

    // Sweep wedge (subtle)
    final sweepAngle = sweep01 * 2 * pi;
    final sweepPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.ally.withOpacity(0.08);
    final path = Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: r), sweepAngle - 0.35, 0.35, false)
      ..close();
    canvas.drawPath(path, sweepPaint);

    // Sweep line
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.ally.withOpacity(0.5);
    final lineEnd = Offset(c.dx + cos(sweepAngle) * r, c.dy + sin(sweepAngle) * r);
    canvas.drawLine(c, lineEnd, linePaint);

    // Pings
    for (final p in pings) {
      if (!p.hasBearing) continue;
      final pr = r * p.radius01;
      final pt = Offset(c.dx + cos(p.angleRad) * pr, c.dy + sin(p.angleRad) * pr);

      final color = (p.kind == RadarPingKind.ally) ? AppColors.ally : AppColors.enemy;

      // glow
      canvas.drawCircle(pt, 10, Paint()..color = color.withOpacity(0.18));
      // dot
      canvas.drawCircle(pt, 5.5, Paint()..color = color.withOpacity(0.95));
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.sweep01 != sweep01 || oldDelegate.pings != pings;
  }
}
