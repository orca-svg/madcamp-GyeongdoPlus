import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/section_title.dart';
import '../../providers/radar_provider.dart';
import '../../watch/radar_packet.dart';
import '../../watch/watch_bridge.dart';
import 'widgets/radar_painter.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  late final Timer _timer;
  double _sweep = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      setState(() {
        _sweep += 0.008;
        if (_sweep > 1) _sweep -= 1;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(radarProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, AppDimens.bottomBarHIn + 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('전술 레이더', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('실시간 위치 추적', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _legendDot(AppColors.borderCyan, '아군'),
                    const SizedBox(width: 14),
                    _legendDot(AppColors.red, '적'),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: GlowCard(
                    glowColor: AppColors.borderCyan.withOpacity(0.14),
                    borderColor: AppColors.borderCyan.withOpacity(0.45),
                    padding: const EdgeInsets.all(18),
                    child: SizedBox(
                      width: 270,
                      height: 270,
                      child: ClipOval(
                        child: Container(
                          color: AppColors.surface2.withOpacity(0.25),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: CustomPaint(painter: RadarPainter(sweep01: _sweep, pings: s.pings)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _miniStat(icon: Icons.group_rounded, value: '${s.allyCount}', label: '아군', border: AppColors.borderCyan)),
                    const SizedBox(width: 12),
                    Expanded(child: _miniStat(icon: Icons.warning_rounded, value: '${s.enemyCount}', label: '적', border: AppColors.red)),
                    const SizedBox(width: 12),
                    Expanded(child: _miniStat(icon: Icons.shield_rounded, value: '안전', label: '상태', border: AppColors.lime)),
                  ],
                ),
                const SizedBox(height: 16),
                const SectionTitle(title: '위험 분석'),
                const SizedBox(height: 10),
                GlowCard(
                  borderColor: AppColors.orange.withOpacity(0.45),
                  glowColor: AppColors.orange.withOpacity(0.10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.orange)),
                          const SizedBox(width: 10),
                          Text(
                            s.dangerTitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.orange),
                          ),
                          const Spacer(),
                          Text(
                            s.etaText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.red, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('방향: ${s.directionText}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('거리: ${s.distanceText}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: s.progress01,
                          minHeight: 10,
                          backgroundColor: AppColors.outlineLow.withOpacity(0.9),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GlowCard(
                        glow: false,
                        borderColor: AppColors.outlineLow,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('현재 상태', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                            const SizedBox(height: 10),
                            Text(s.safetyText, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlowCard(
                        glow: false,
                        borderColor: AppColors.outlineLow,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('권장 행동', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                            const SizedBox(height: 10),
                            Text('엄폐물로 이동', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final ok = await WatchBridge.isPairedOrConnected();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Watch connected: $ok')));
                        },
                        icon: const Icon(Icons.watch_rounded, size: 18),
                        label: const Text('연결 확인'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          ref.read(radarProvider.notifier).randomize();

                          final s = ref.read(radarProvider);
                          final packet = RadarPacketDto(
                            headingDeg: 72, // TODO: 실제 heading 센서 값으로 교체
                            ttlMs: 7000,
                            captureProgress01: s.progress01,
                            warningDirectionDeg: null,
                            pings: const [
                              RadarPingDto(kind: "JAIL", bearingDeg: 210, distanceM: 35, confidence: 0.9),
                              RadarPingDto(kind: "NEAREST_THIEF", bearingDeg: 15, distanceM: 12, confidence: 0.6),
                            ],
                          );

                          await WatchBridge.sendRadarPacket(packet);
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('샘플 갱신'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
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

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _miniStat({required IconData icon, required String value, required String label, required Color border}) {
    return GlowCard(
      borderColor: border.withOpacity(0.55),
      glowColor: border.withOpacity(0.10),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Column(
        children: [
          Icon(icon, color: border, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
