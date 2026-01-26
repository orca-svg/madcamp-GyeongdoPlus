import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
        ],
      ],
    );
  }
}
