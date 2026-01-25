import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../core/widgets/ws_status_pill.dart';
import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../net/ws/dto/match_state.dart';
import '../../providers/game_phase_provider.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/match_sync_provider.dart';
import '../../providers/room_provider.dart';
import '../../net/ws/ws_client_provider.dart';
import '../../providers/ws_ui_status_provider.dart';

class MatchScreen extends ConsumerWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final rules = ref.watch(matchRulesProvider);
    final sync = ref.watch(matchSyncProvider);
    final wsUi = ref.watch(wsUiStatusProvider);
    final isHost = room.amIHost;
    final lastState = sync.lastMatchState?.payload;

    if (lastState == null) {
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
                  Text('경기 설정', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  WsStatusPill(
                    model: wsUi,
                    onReconnect: wsUi.showReconnect ? () => ref.read(wsConnectionProvider.notifier).userReconnect() : null,
                  ),
                  const SizedBox(height: 14),
                  _ServerSyncCard(
                    state: null,
                    matchId: sync.currentMatchId,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                Text('경기 설정', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  '방장만 게임 시간을 변경할 수 있습니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                WsStatusPill(
                  model: wsUi,
                  onReconnect: wsUi.showReconnect ? () => ref.read(wsConnectionProvider.notifier).userReconnect() : null,
                ),
                const SizedBox(height: 10),
                _ServerSyncCard(
                  state: lastState,
                  matchId: sync.currentMatchId ?? sync.lastMatchState?.payload.matchId,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SideCard(
                        title: '경찰',
                        value: '${room.policeCount}',
                        accent: AppColors.borderCyan,
                        icon: Icons.shield_rounded,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SideCard(
                        title: '도둑',
                        value: '${room.thiefCount}',
                        accent: AppColors.red,
                        icon: Icons.lock_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: Text('시간 조절', style: Theme.of(context).textTheme.titleMedium)),
                    if (!isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface2.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.outlineLow),
                        ),
                        child: const Text(
                          'READ ONLY',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _TimeControlCard(
                  enabled: isHost,
                  durationMin: rules.durationMin,
                  onChanged: (v) {
                    ref.read(matchRulesProvider.notifier).setDurationMin(v);
                    // TODO: 서버 시간 변경 메시지 스키마 확정 후 WS(action/patch 등)로 전송.
                  },
                ),
                const SizedBox(height: 22),
                Text('규칙 요약', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _RulesSummaryCard(
                  rules: rules,
                ),
                const SizedBox(height: 22),
                Text('지도 미리보기', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _ArenaMapPreviewCard(
                  polygon: rules.zonePolygon,
                  jailCenter: rules.jailCenter,
                  jailRadiusM: rules.jailRadiusM,
                ),
                const SizedBox(height: 22),
                Text('테스트', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                GradientButton(
                  variant: GradientButtonVariant.joinRoom,
                  title: '경기 종료(테스트)',
                  onPressed: () => ref.read(gamePhaseProvider.notifier).toPostGame(),
                  leading: const Icon(Icons.flag_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeControlCard extends StatelessWidget {
  final bool enabled;
  final int durationMin;
  final ValueChanged<int> onChanged;

  const _TimeControlCard({
    required this.enabled,
    required this.durationMin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final v = durationMin.clamp(1, 60);
    return GlowCard(
      glow: false,
      borderColor: enabled ? AppColors.borderCyan.withOpacity(0.35) : AppColors.outlineLow,
      child: Opacity(
        opacity: enabled ? 1 : 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('게임 시간', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  key: const Key('matchTimeMinus'),
                  onPressed: enabled && v > 1 ? () => onChanged(v - 1) : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  color: AppColors.textSecondary,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '$v분',
                      key: const Key('matchTimeValue'),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('matchTimePlus'),
                  onPressed: enabled && v < 60 ? () => onChanged(v + 1) : null,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 2),
            AbsorbPointer(
              absorbing: !enabled,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.borderCyan,
                  inactiveTrackColor: AppColors.outlineLow.withOpacity(0.9),
                  thumbColor: AppColors.borderCyan,
                  overlayColor: AppColors.borderCyan.withOpacity(0.12),
                ),
                child: Slider(
                  key: const Key('matchTimeSlider'),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  value: v.toDouble(),
                  onChanged: (d) => onChanged(d.round()),
                ),
              ),
            ),
            if (!enabled) ...[
              const SizedBox(height: 6),
              Text(
                '방장만 변경할 수 있습니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RulesSummaryCard extends StatelessWidget {
  final MatchRulesState rules;

  const _RulesSummaryCard({
    required this.rules,
  });

  @override
  Widget build(BuildContext context) {
    final poly = rules.zonePolygon;
    final zoneText =
        (poly == null || poly.isEmpty) ? '미설정(—)' : (poly.length >= 3 ? '${poly.length}점 설정됨' : '점이 ${poly.length}개(최소 3)');
    final jailText = (rules.jailCenter != null && rules.jailRadiusM != null) ? '설정됨 (${rules.jailRadiusM!.round()}m)' : '미설정(—)';
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(label: '모드', value: rules.gameMode.label),
          const SizedBox(height: 10),
          _row(label: '인원', value: '${rules.maxPlayers}명'),
          const SizedBox(height: 10),
          _row(label: '해방', value: rules.releaseMode),
          const SizedBox(height: 10),
          _row(label: '맵', value: rules.mapName),
          const SizedBox(height: 10),
          _row(label: '구역', value: zoneText),
          const SizedBox(height: 10),
          _row(label: '감옥', value: jailText),
        ],
      ),
    );
  }

  Widget _row({required String label, required String value}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ArenaMapPreviewCard extends StatelessWidget {
  final List<GeoPointDto>? polygon;
  final GeoPointDto? jailCenter;
  final double? jailRadiusM;

  const _ArenaMapPreviewCard({
    required this.polygon,
    required this.jailCenter,
    required this.jailRadiusM,
  });

  @override
  Widget build(BuildContext context) {
    final poly = polygon;
    final hasJail = jailCenter != null && jailRadiusM != null;
    final hasPolygon = poly != null && poly.length >= 3;

    if (!hasPolygon && !hasJail) {
      return _noticeCard(context, '구역/감옥이 미설정입니다.');
    }

    if (!hasPolygon && !hasJail && (poly != null && poly.isNotEmpty)) {
      return _noticeCard(context, '구역 점이 ${poly.length}개입니다. (최소 3개 필요)');
    }

    const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
    if (isFlutterTest) {
      return _noticeCard(context, '테스트 환경에서는 지도 미리보기가 비활성화됩니다.');
    }

    final kakaoJsAppKey = (dotenv.isInitialized ? dotenv.env['KAKAO_JS_APP_KEY'] : null)?.trim() ?? '';
    if (kakaoJsAppKey.isEmpty) {
      return _noticeCard(
        context,
        'KAKAO_JS_APP_KEY가 설정되지 않아 지도를 표시할 수 없습니다.\n'
        'frontend/.env에 키를 넣어주세요.',
      );
    }

    final points = (poly ?? const <GeoPointDto>[]).map((p) => LatLng(p.lat, p.lng)).toList(growable: false);
    final center = (hasJail) ? LatLng(jailCenter!.lat, jailCenter!.lng) : _centroid(points);

    final polygonOverlay = hasPolygon
        ? Polygon(
            polygonId: 'arena_polygon',
            points: points,
            strokeWidth: 3,
            strokeColor: AppColors.borderCyan,
            strokeOpacity: 0.9,
            fillColor: AppColors.borderCyan,
            fillOpacity: 0.12,
            zIndex: 1,
          )
        : null;

    final jailCircle = hasJail
        ? Circle(
            circleId: 'jail_circle',
            center: LatLng(jailCenter!.lat, jailCenter!.lng),
            radius: jailRadiusM,
            strokeWidth: 2,
            strokeColor: AppColors.purple,
            strokeOpacity: 0.9,
            fillColor: AppColors.purple,
            fillOpacity: 0.12,
            zIndex: 2,
          )
        : null;

    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        child: SizedBox(
          height: 220,
          child: Stack(
            children: [
              KakaoMap(
                center: center,
                currentLevel: 4,
                zoomControl: false,
                mapTypeControl: false,
                polygons: polygonOverlay == null ? null : [polygonOverlay],
                circles: jailCircle == null ? null : [jailCircle],
                onMapCreated: (controller) {
                  if (hasPolygon && points.isNotEmpty) controller.fitBounds(points);
                },
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface2.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.outlineLow),
                  ),
                  child: const Text(
                    'READ ONLY',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noticeCard(BuildContext context, String message) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  LatLng _centroid(List<LatLng> points) {
    var lat = 0.0;
    var lng = 0.0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }
}

class _ServerSyncCard extends StatelessWidget {
  final MatchStateDto? state;
  final String? matchId;

  const _ServerSyncCard({
    required this.state,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s == null) {
      return GlowCard(
        glow: true,
        glowColor: AppColors.borderCyan.withOpacity(0.10),
        borderColor: AppColors.borderCyan.withOpacity(0.25),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.borderCyan),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '서버 동기화 대기 중…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            if (matchId != null && matchId!.isNotEmpty)
              Text(
                matchId!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
          ],
        ),
      );
    }

    final endsAt = s.time.endsAtMs;
    final remainText = (endsAt == null || s.time.serverNowMs == 0) ? '—' : _formatRemaining(s.time.serverNowMs, endsAt);

    final score = s.live.score;
    final cap = s.live.captureProgress?.progress01;
    final rescue = s.live.rescueProgress?.progress01;

    final capText = (cap == null) ? '—' : '${(cap * 100).round()}%';
    final rescueText = (rescue == null) ? '—' : '${(rescue * 100).round()}%';

    return GlowCard(
      glow: true,
      glowColor: AppColors.borderCyan.withOpacity(0.10),
      borderColor: AppColors.borderCyan.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_rounded, color: AppColors.lime, size: 18),
              const SizedBox(width: 8),
              Text('서버 스냅샷', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text(
                s.matchId,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MiniPill(label: 'state', value: s.state),
              _MiniPill(label: 'mode', value: s.mode),
              _MiniPill(label: '남은시간', value: remainText),
              if (score != null) _MiniPill(label: '도둑', value: '${score.thiefFree}F/${score.thiefCaptured}C'),
              _MiniPill(label: 'capture', value: capText),
              _MiniPill(label: 'rescue', value: rescueText),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final String value;

  const _MiniPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineLow.withOpacity(0.8)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          children: [
            TextSpan(text: '$label  '),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRemaining(int serverNowMs, int endsAtMs) {
  final remain = endsAtMs - serverNowMs;
  if (remain <= 0) return '0:00';
  final d = Duration(milliseconds: remain);
  final m = d.inMinutes;
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}


class _SideCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  const _SideCard({required this.title, required this.value, required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: accent.withOpacity(0.10),
      borderColor: accent.withOpacity(0.35),
      child: SizedBox(
        height: 96,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Text(value, style: TextStyle(color: accent, fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
