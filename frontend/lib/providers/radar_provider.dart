import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RadarPingKind { ally, enemy }

class RadarPing {
  final RadarPingKind kind;
  final double angleRad; // 0..2pi
  final double radius01; // 0..1
  const RadarPing({
    required this.kind,
    required this.angleRad,
    required this.radius01,
  });
}

class RadarUiState {
  final int allyCount;
  final int enemyCount;
  final String safetyText;
  final bool danger;
  final String dangerTitle;
  final String directionText;
  final String distanceText;
  final String etaText;
  final double progress01;
  final List<RadarPing> pings;

  const RadarUiState({
    required this.allyCount,
    required this.enemyCount,
    required this.safetyText,
    required this.danger,
    required this.dangerTitle,
    required this.directionText,
    required this.distanceText,
    required this.etaText,
    required this.progress01,
    required this.pings,
  });

  RadarUiState copyWith({
    int? allyCount,
    int? enemyCount,
    String? safetyText,
    bool? danger,
    String? dangerTitle,
    String? directionText,
    String? distanceText,
    String? etaText,
    double? progress01,
    List<RadarPing>? pings,
  }) {
    return RadarUiState(
      allyCount: allyCount ?? this.allyCount,
      enemyCount: enemyCount ?? this.enemyCount,
      safetyText: safetyText ?? this.safetyText,
      danger: danger ?? this.danger,
      dangerTitle: dangerTitle ?? this.dangerTitle,
      directionText: directionText ?? this.directionText,
      distanceText: distanceText ?? this.distanceText,
      etaText: etaText ?? this.etaText,
      progress01: progress01 ?? this.progress01,
      pings: pings ?? this.pings,
    );
  }
}

class RadarController extends Notifier<RadarUiState> {
  @override
  RadarUiState build() {
    final initial = RadarUiState(
      allyCount: 3,
      enemyCount: 2,
      safetyText: '안전\n상태',
      danger: true,
      dangerTitle: '경고: 적 접근 중',
      directionText: '북동쪽 방향',
      distanceText: '~45m',
      etaText: '12초',
      progress01: 0.72,
      pings: const [],
    );
    // 초기 샘플 점 생성
    return _seed(initial);
  }

  RadarUiState _seed(RadarUiState base) {
    final rng = Random(7);
    final pings = <RadarPing>[
      for (int i = 0; i < 3; i++)
        RadarPing(
          kind: RadarPingKind.ally,
          angleRad: rng.nextDouble() * pi * 2,
          radius01: 0.25 + rng.nextDouble() * 0.6,
        ),
      for (int i = 0; i < 2; i++)
        RadarPing(
          kind: RadarPingKind.enemy,
          angleRad: rng.nextDouble() * pi * 2,
          radius01: 0.25 + rng.nextDouble() * 0.6,
        ),
    ];
    return base.copyWith(pings: pings);
  }

  void randomize() {
    state = _seed(state);
  }
}

final radarProvider = NotifierProvider<RadarController, RadarUiState>(
  RadarController.new,
);
