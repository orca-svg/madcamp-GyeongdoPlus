import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../net/ws/dto/match_state.dart';
import '../net/ws/dto/radar_ping.dart';
import '../net/ws/ws_envelope.dart';
import 'match_sync_provider.dart';
import 'room_provider.dart';

enum RadarPingKind { ally, enemy }

class RadarPing {
  final RadarPingKind kind;
  final double angleRad; // 0..2pi
  final double radius01; // 0..1
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
  final sync = ref.watch(matchSyncProvider);
  final room = ref.watch(roomProvider);

  final match = sync.lastMatchState?.payload;
  final pingEnvelope = sync.lastRadarPing;
  final ping = pingEnvelope?.payload;

  final progress = match?.live.captureProgress?.progress01 ?? 0.0;

  // Check if radar ping has expired based on TTL
  final isPingValid = _isPingValid(pingEnvelope);
  final validPing = isPingValid ? ping : null;

  final pings = _buildUiPings(validPing);
  final allyCount = room.policeCount;
  final enemyCount = room.thiefCount;

  final danger = (validPing?.pings.isNotEmpty ?? false) || (match?.state == 'RUNNING');
  final dangerTitle = danger ? '경고: 주변 신호 감지' : '상태 양호';

  return RadarUiState(
    allyCount: allyCount,
    enemyCount: enemyCount,
    safetyText: (match?.state ?? '—'),
    danger: danger,
    dangerTitle: dangerTitle,
    directionText: _directionText(validPing),
    distanceText: _distanceText(validPing),
    etaText: _etaText(match),
    progress01: progress.clamp(0.0, 1.0),
    pings: pings,
  );
});

List<RadarPing> _buildUiPings(RadarPingPayload? payload) {
  if (payload == null) return const [];

  const maxRangeM = 60.0;
  return [
    for (final p in payload.pings)
      _buildPing(p, maxRangeM),
  ];
}

RadarPing _buildPing(RadarPingVector p, double maxRangeM) {
  final hasBearing = p.bearingDeg.isFinite;
  return RadarPing(
    kind: _kindFromServer(p.kind),
    angleRad: hasBearing ? _degToRad(p.bearingDeg) : 0.0,
    radius01: (p.distanceM / maxRangeM).clamp(0.0, 1.0),
    hasBearing: hasBearing,
    distanceM: p.distanceM,
  );
}

RadarPingKind _kindFromServer(String kind) {
  final k = kind.toUpperCase();
  if (k.contains('ALLY') || k.contains('FRIEND') || k.contains('POLICE')) return RadarPingKind.ally;
  if (k.contains('ENEMY') || k.contains('THIEF')) return RadarPingKind.enemy;
  return RadarPingKind.enemy;
}

double _degToRad(double deg) => (deg % 360) * pi / 180.0;

String _directionText(RadarPingPayload? payload) {
  if (payload == null || payload.pings.isEmpty) return '—';
  final bearing = payload.pings.first.bearingDeg % 360;
  if (bearing < 45 || bearing >= 315) return '북쪽 방향';
  if (bearing < 135) return '동쪽 방향';
  if (bearing < 225) return '남쪽 방향';
  return '서쪽 방향';
}

String _distanceText(RadarPingPayload? payload) {
  if (payload == null || payload.pings.isEmpty) return '—';
  final d = payload.pings.first.distanceM;
  return '~${d.toStringAsFixed(0)}m';
}

String _etaText(MatchStateDto? match) {
  if (match == null) return '—';
  final now = match.time.serverNowMs;
  final endsAt = match.time.endsAtMs;
  if (endsAt == null) return '—';
  final remain = max(0, endsAt - now);
  return '${(remain / 1000).toStringAsFixed(0)}초';
}

bool _isPingValid(WsEnvelope<RadarPingPayload>? envelope) {
  if (envelope == null) return false;
  final ping = envelope.payload;
  final receivedAtMs = envelope.ts ?? 0;
  if (receivedAtMs == 0) return true; // No timestamp, assume valid

  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final elapsedMs = nowMs - receivedAtMs;
  final ttlMs = ping.ttlMs;

  // Ping is valid if it hasn't exceeded TTL
  return elapsedMs < ttlMs;
}
