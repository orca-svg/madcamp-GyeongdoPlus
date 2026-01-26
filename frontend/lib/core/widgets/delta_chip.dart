import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DeltaChip extends StatelessWidget {
  final double delta;
  final String? suffix;

  const DeltaChip({super.key, required this.delta, this.suffix});

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    final bg = positive ? AppColors.chipPositiveBg : AppColors.chipNegativeBg;
    final fg = positive ? AppColors.chipPositiveFg : AppColors.chipNegativeFg;
    final icon = positive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final sign = positive ? '+' : '';
    final label = '$sign${delta.toStringAsFixed(1)}${suffix ?? ''}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

