import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/section_title.dart';
import '../../providers/radar_provider.dart';
import 'widgets/radar_painter.dart';
import '../../watch/watch_bridge.dart';
import '../../watch/radar_packet.dart';


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

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('전술 레이더', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('실시간 위치 추적', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legendDot(AppColors.ally, '아군'),
              const SizedBox(width: 14),
              _legendDot(AppColors.enemy, '적'),
            ],
          ),
          const SizedBox(height: 8),

          // Radar
          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface2.withOpacity(0.35),
                boxShadow: [
                  BoxShadow(color: AppColors.ally.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 10)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: CustomPaint(
                  painter: RadarPainter(sweep01: _sweep, pings: s.pings),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3 cards row
          Row(
            children: [
              Expanded(child: _miniStat(icon: Icons.group_rounded, value: '${s.allyCount}', label: '아군', border: AppColors.ally)),
              const SizedBox(width: 12),
              Expanded(child: _miniStat(icon: Icons.warning_rounded, value: '${s.enemyCount}', label: '적', border: AppColors.enemy)),
              const SizedBox(width: 12),
              Expanded(child: _miniStat(icon: Icons.shield_rounded, value: '안전', label: '상태', border: AppColors.safe)),
              ElevatedButton(
                onPressed: () async {
                  final ok = await WatchBridge.isPairedOrConnected();
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Watch connected: $ok')),
                  );
                },
                child: const Text('Watch 연결 확인'),
              )
            ],
          ),

          const SizedBox(height: 18),
          const SectionTitle(title: '위험 분석'),
          const SizedBox(height: 10),

          GlowCard(
            borderColor: AppColors.warn.withOpacity(0.65),
            glowColor: AppColors.warn.withOpacity(0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.warn)),
                    const SizedBox(width: 10),
                    Text(s.dangerTitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.warn)),
                    const Spacer(),
                    Text(s.distanceText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(s.directionText, style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    Text(s.etaText, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.enemy, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: s.progress01,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.warn.withOpacity(0.9)),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                ref.read(radarProvider.notifier).randomize();

                // (샘플) 워치로 보낼 패킷 구성
                final s = ref.read(radarProvider);
                final packet = RadarPacketDto(
                  headingDeg: 72, // TODO: 실제 heading 센서 값으로 교체
                  ttlMs: 7000,
                  captureProgress01: s.progress01,
                  warningDirectionDeg: null,
                  pings: [
                    // s.pings를 kind/bearing/distance로 매핑하는 게 정석(지금은 샘플)
                    const RadarPingDto(kind: "JAIL", bearingDeg: 210, distanceM: 35, confidence: 0.9),
                    const RadarPingDto(kind: "NEAREST_THIEF", bearingDeg: 15, distanceM: 12, confidence: 0.6),
                  ],
                );

                await WatchBridge.sendRadarPacket(packet);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('샘플 갱신'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
