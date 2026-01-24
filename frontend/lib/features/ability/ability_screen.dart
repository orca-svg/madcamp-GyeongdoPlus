import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AbilityScreen extends StatelessWidget {
  const AbilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('능력(준비 중)', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
