import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('통계(준비 중)', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
