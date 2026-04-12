import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'game_provider.dart';
import 'room_provider.dart';

enum RadarPingKind { ally, enemy }

class RadarPing {
  final RadarPingKind kind;
  final double angleRad;
  final double radius01;
  final bool hasBearing;
  final double distanceM;

  const RadarPing({
    required this.kind,
    required this.angleRad,
    required this.radius01,
    required this.hasBearing,
    required this.distanceM,
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
}

final radarProvider = Provider<RadarUiState>((ref) {
  final game = ref.watch(gameProvider);
  final room = ref.watch(roomProvider);
  final myPos = game.myPosition;
  final myTeam = room.me?.team == Team.police ? 'POLICE' : 'THIEF';

  if (myPos == null) {
    return const RadarUiState(
      allyCount: 0,
      enemyCount: 0,
      safetyText: '위치 대기',
      danger: false,
      dangerTitle: '신호 없음',
      directionText: '—',
      distanceText: '—',
      etaText: '—',
      progress01: 0,
      pings: [],
    );
  }

  final pings = <RadarPing>[];
  RadarPing? closestEnemy;

  for (final player in game.players.values) {
    if (player.userId == room.myId) continue;

    final distance = Geolocator.distanceBetween(
      myPos.latitude,
      myPos.longitude,
      player.lat,
      player.lng,
    );
    final bearing = Geolocator.bearingBetween(
      myPos.latitude,
      myPos.longitude,
      player.lat,
      player.lng,
    );
    final heading = myPos.heading.isNaN ? 0.0 : myPos.heading;
    final relativeBearing = ((bearing - heading) + 360.0) % 360.0;
    final ping = RadarPing(
      kind: player.team == myTeam ? RadarPingKind.ally : RadarPingKind.enemy,
      angleRad: relativeBearing * pi / 180.0,
      radius01: (distance / 120.0).clamp(0.0, 1.0),
      hasBearing: true,
      distanceM: distance,
    );
    pings.add(ping);

    if (ping.kind == RadarPingKind.enemy &&
        (closestEnemy == null || ping.distanceM < closestEnemy.distanceM)) {
      closestEnemy = ping;
    }
  }

  final allyCount = pings.where((p) => p.kind == RadarPingKind.ally).length;
  final enemyCount = pings.where((p) => p.kind == RadarPingKind.enemy).length;
  final directionText = closestEnemy == null
      ? '—'
      : _directionText(closestEnemy.angleRad);
  final distanceText = closestEnemy == null
      ? '—'
      : '~${closestEnemy.distanceM.round()}m';

  return RadarUiState(
    allyCount: allyCount,
    enemyCount: enemyCount,
    safetyText: enemyCount > 0 ? '주변 적 감지' : '안전',
    danger: enemyCount > 0,
    dangerTitle: enemyCount > 0 ? '경고: 주변 신호 감지' : '신호 없음',
    directionText: directionText,
    distanceText: distanceText,
    etaText: '—',
    progress01: 0,
    pings: pings,
  );
});

String _directionText(double angleRad) {
  final deg = (angleRad * 180 / pi) % 360;
  if (deg < 45 || deg >= 315) return '정면';
  if (deg < 135) return '오른쪽';
  if (deg < 225) return '후방';
  return '왼쪽';
}
