import 'package:flutter/material.dart';
import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/delta_chip.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/stat_ring.dart';
import '../match/widgets/ingame_hud.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  14 + 118,
                  18,
                  AppDimens.bottomBarHIn + 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('성능 통계', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('시즌 12 퍼포먼스', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 14),
                GlowCard(
                  glowColor: AppColors.borderCyan.withOpacity(0.18),
                  borderColor: AppColors.borderCyan.withOpacity(0.55),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(child: Center(child: StatRing(value01: 0.72, label: '체포율'))),
                      Expanded(child: Center(child: StatRing(value01: 0.45, label: '정확도'))),
                      Expanded(child: Center(child: StatRing(value01: 0.88, label: '반응속도'))),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text('상세 통계', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _detailRow(
                  title: '평균 킬',
                  value: '8.4',
                  delta: 1.2,
                  positive: true,
                ),
                const SizedBox(height: 12),
                _detailRow(
                  title: '평균 데스',
                  value: '3.2',
                  delta: -0.8,
                  positive: false,
                ),
                const SizedBox(height: 12),
                _detailRow(
                  title: 'K/D 비율',
                  value: '2.63',
                  delta: 0.4,
                  positive: true,
                ),
                const SizedBox(height: 12),
                _detailRow(
                  title: '생존율',
                  value: '67%',
                  delta: 5.0,
                  positive: true,
                  suffix: '%',
                ),
                const SizedBox(height: 22),
                Text('월간 추이', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                GlowCard(
                  glowColor: AppColors.lime.withOpacity(0.14),
                  borderColor: AppColors.lime.withOpacity(0.45),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 130,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            _Bar(value01: 0.58, label: '월'),
                            _Bar(value01: 0.66, label: '화'),
                            _Bar(value01: 0.49, label: '수'),
                            _Bar(value01: 0.74, label: '목'),
                            _Bar(value01: 0.68, label: '금'),
                            _Bar(value01: 0.82, label: '토'),
                            _Bar(value01: 0.76, label: '일'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
              const Positioned(
                left: 18,
                right: 18,
                top: 14,
                child: IgnorePointer(child: IngameHud()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow({
    required String title,
    required String value,
    required double delta,
    required bool positive,
    String? suffix,
  }) {
    final border = positive ? AppColors.lime : AppColors.red;
    final icon = positive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    return GlowCard(
      glowColor: border.withOpacity(0.10),
      borderColor: border.withOpacity(0.35),
      gradientSurface: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          DeltaChip(delta: delta, suffix: suffix),
          const SizedBox(width: 10),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: border.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border.withOpacity(0.20)),
            ),
            child: Icon(icon, color: border, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value01;
  final String label;

  const _Bar({required this.value01, required this.label});

  @override
  Widget build(BuildContext context) {
    final h = 96.0 * value01 + 18;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [AppColors.graphCyan, AppColors.graphLime],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.graphLime.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
