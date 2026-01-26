import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/match_rules_provider.dart';
import '../room/room_create_payload.dart';

class ZoneSetupPlaceholderScreen extends StatelessWidget {
  const ZoneSetupPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Remove once all flows use ZoneEditorScreen directly.
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('구역 설정'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Center(
              child: GlowCard(
                glow: false,
                borderColor: AppColors.outlineLow,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이번 단계에서는 지도 편집을 비활성화했습니다.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '폴리곤/감옥 값은 다음 단계에서 편집 UI로 연결됩니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      variant: GradientButtonVariant.createRoom,
                      title: '샘플 구역 적용',
                      height: 50,
                      borderRadius: 14,
                      onPressed: () {
                        Navigator.of(context).pop(_dummyZone());
                      },
                      leading: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

ZoneSetupResult _dummyZone() {
  return ZoneSetupResult(
    polygon: const [
      GeoPointDto(lat: 37.5675, lng: 126.9782),
      GeoPointDto(lat: 37.5679, lng: 126.9825),
      GeoPointDto(lat: 37.5652, lng: 126.9831),
      GeoPointDto(lat: 37.5648, lng: 126.9790),
    ],
    jailCenter: const GeoPointDto(lat: 37.5665, lng: 126.9812),
    jailRadiusM: 12,
  );
}
