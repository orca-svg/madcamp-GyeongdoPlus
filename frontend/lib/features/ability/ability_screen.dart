import 'package:flutter/material.dart';
import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';

class AbilityScreen extends StatelessWidget {
  const AbilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, AppDimens.bottomBarHIn + 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('능력', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('장비 및 스킬 세팅', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 14),
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  child: Row(
                    children: const [
                      Icon(Icons.auto_fix_high_rounded, color: AppColors.borderCyan),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '능력 화면은 다음 단계에서 구성됩니다.\n공용 카드/리스트 패턴은 이미 적용되어 있습니다.',
                          style: TextStyle(color: AppColors.textSecondary, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
