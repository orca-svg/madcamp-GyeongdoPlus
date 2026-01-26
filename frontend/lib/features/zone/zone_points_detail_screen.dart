import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/match_rules_provider.dart';

class ZonePointsDetailScreen extends StatelessWidget {
  final List<GeoPointDto> points;

  const ZonePointsDetailScreen({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('구역 포인트'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        points.isEmpty ? '폴리곤: 미설정' : '폴리곤: ${points.length}점',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GradientButton(
                              variant: GradientButtonVariant.joinRoom,
                              height: 44,
                              borderRadius: 14,
                              title: 'JSON 복사',
                              onPressed: points.isEmpty
                                  ? null
                                  : () => _copyJson(context),
                              leading: const Icon(
                                Icons.content_copy_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GradientButton(
                              variant: GradientButtonVariant.createRoom,
                              height: 44,
                              borderRadius: 14,
                              title: 'CSV 복사',
                              onPressed: points.isEmpty
                                  ? null
                                  : () => _copyCsv(context),
                              leading: const Icon(
                                Icons.table_chart_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GlowCard(
                    glow: false,
                    borderColor: AppColors.outlineLow,
                    child: points.isEmpty
                        ? Center(
                            child: Text(
                              '포인트가 없습니다.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: points.length,
                            separatorBuilder: (_, _) => const Divider(
                              color: AppColors.outlineLow,
                              height: 1,
                            ),
                            itemBuilder: (context, i) {
                              final p = points[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 34,
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${p.lat.toStringAsFixed(6)}, ${p.lng.toStringAsFixed(6)}',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyJson(BuildContext context) async {
    final jsonText = jsonEncode(points.map((p) => p.toJson()).toList());
    await Clipboard.setData(ClipboardData(text: jsonText));
    if (!context.mounted) return;
    showAppSnackBar(context, message: 'JSON이 복사되었습니다');
  }

  Future<void> _copyCsv(BuildContext context) async {
    final buf = StringBuffer()..writeln('lat,lng');
    for (final p in points) {
      buf.writeln('${p.lat},${p.lng}');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!context.mounted) return;
    showAppSnackBar(context, message: 'CSV가 복사되었습니다');
  }
}
