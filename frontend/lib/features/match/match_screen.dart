import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('매치(준비 중)', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
