import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_card.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/ws_status_pill.dart';
import '../../net/ws/dto/match_state.dart';
import '../../net/ws/dto/radar_ping.dart';
import '../../net/ws/ws_envelope.dart';
import '../../net/ws/ws_client_provider.dart';
import '../../net/ws/ws_types.dart';
import '../../providers/match_mode_provider.dart';
import '../../providers/match_rules_provider.dart';
import '../../providers/match_sync_provider.dart';
import '../../providers/radar_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/watch_provider.dart';
import '../../providers/ws_ui_status_provider.dart';
import '../match/widgets/ingame_hud.dart';
import '../../providers/match_state_sim_provider.dart';
import 'widgets/radar_painter.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  late final Timer _timer;
  double _sweep = 0;
  late final ProviderSubscription<int?> _noticeSub;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      setState(() {
        _sweep += 0.008;
        if (_sweep > 1) _sweep -= 1;
      });
    });

    _noticeSub = ref.listenManual<int?>(
      matchStateSimProvider.select((s) => s?.noticeSeq),
      (prev, next) {
        if (!mounted) return;
        if (next == null || next == prev) return;
        final msg = ref.read(matchStateSimProvider)?.noticeMessage ?? '';
        if (msg.isEmpty) return;
        showAppSnackBar(context, message: msg);
      },
    );
  }

  @override
  void dispose() {
    _noticeSub.close();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(radarProvider);
    final sync = ref.watch(matchSyncProvider);
    final room = ref.watch(roomProvider);
    final wsConn = ref.watch(wsConnectionProvider);
    final wsUiStatus = ref.watch(wsUiStatusProvider);
    final watchConnected = ref.watch(watchConnectedProvider);
    final gameMode = ref.watch(currentGameModeProvider);

    final match = sync.lastMatchState?.payload;
    final ping = sync.lastRadarPing?.payload;

    final myTeam = room.me?.team == Team.thief ? 'THIEF' : 'POLICE';

    // 팀 현황 계산
    final teamStats = _computeTeamStats(match);

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
                // A. 상단 타이틀 row: 전술 레이더 + Watch + WsStatusPill
                _buildTitleRow(context, watchConnected, wsUiStatus),
                const SizedBox(height: 12),

                // B. 팀 현황 카드 3개 (레이더 캔버스 상단)
                _buildTeamStatusRow(context, teamStats),
                const SizedBox(height: 14),

                if (kDebugMode) ...[
                  GlowCard(
                    glow: false,
                    borderColor: AppColors.outlineLow,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Text(
                      _summaryLine(match: match, myTeam: myTeam, ping: ping),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 범례
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _legendDot(AppColors.borderCyan, '아군'),
                    const SizedBox(width: 14),
                    _legendDot(AppColors.red, '적'),
                  ],
                ),
                const SizedBox(height: 8),

                // 레이더 캔버스
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
                            child: CustomPaint(painter: RadarPainter(sweep01: _sweep, pings: ui.pings)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (ui.pings.any((p) => !p.hasBearing)) ...[
                  GlowCard(
                    glow: false,
                    borderColor: AppColors.outlineLow,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '방향 미확인 신호',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        for (final p in ui.pings.where((p) => !p.hasBearing))
                          Text(
                            '${p.kind == RadarPingKind.ally ? '아군' : '적'}: ~${p.distanceM.round()}m',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // C/D. 일반 모드가 아닐 때만 위험 분석 섹션 표시
                if (gameMode != GameMode.normal) ...[
                  // 기존 미니 스탯 (아군/적/페이즈)
                  Row(
                    children: [
                      Expanded(child: _miniStat(icon: Icons.group_rounded, value: '${ui.allyCount}', label: '아군', border: AppColors.borderCyan)),
                      const SizedBox(width: 12),
                      Expanded(child: _miniStat(icon: Icons.warning_rounded, value: '${ui.enemyCount}', label: '적', border: AppColors.red)),
                      const SizedBox(width: 12),
                      Expanded(child: _miniStat(icon: Icons.shield_rounded, value: ui.safetyText, label: '페이즈', border: AppColors.lime)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 위험 분석 섹션
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
                              ui.dangerTitle,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.orange),
                            ),
                            const Spacer(),
                            Text(
                              ui.etaText,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.red, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ui.directionText,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            Text(
                              ui.distanceText,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: ui.progress01,
                            minHeight: 10,
                            backgroundColor: AppColors.outlineLow.withOpacity(0.9),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 현재 상태 + 권장 행동 (아이템/능력 모드에서만)
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
                              Text(ui.safetyText, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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
                ] else ...[
                  // 일반 모드: 심박수만 표시
                  _buildHeartRateSection(context, watchConnected),
                ],

                const SizedBox(height: 14),

                // 디버그 버튼들
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      if (kDebugMode)
                        TextButton.icon(
                          onPressed: () => ref.read(wsConnectionProvider.notifier).connect(),
                          icon: const Icon(Icons.link_rounded, size: 18),
                          label: Text('WS 연결 (${wsConn.status.name})'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                        ),
                      if (kDebugMode)
                        TextButton.icon(
                          onPressed: () => ref.read(wsConnectionProvider.notifier).disconnect(),
                          icon: const Icon(Icons.link_off_rounded, size: 18),
                          label: const Text('WS 해제'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                        ),
                      TextButton.icon(
                        onPressed: () async {
                          await ref.read(watchConnectedProvider.notifier).refresh();
                          final ok = ref.read(watchConnectedProvider);
                          if (!context.mounted) return;
                          showAppSnackBar(context, message: 'Watch connected: $ok');
                        },
                        icon: const Icon(Icons.watch_rounded, size: 18),
                        label: const Text('연결 확인'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                      ),
                      if (kDebugMode)
                        TextButton.icon(
                          onPressed: () => _mockRadarPing(ref: ref),
                          icon: const Icon(Icons.waves_rounded, size: 18),
                          label: const Text('Mock RadarPing 수신'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),

                // 디버그 JSON
                if (kDebugMode && (sync.lastJsonPreview ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const SectionTitle(title: '디버그 JSON'),
                  const SizedBox(height: 10),
                  GlowCard(
                    glow: false,
                    borderColor: AppColors.outlineLow,
                    child: SelectableText(
                      sync.lastJsonPreview!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                top: 14,
                child: IgnorePointer(
                  child: IngameHud(key: const Key('ingameHud')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A. 상단 타이틀 row: 전술 레이더 + Watch indicator + WsStatusPill
  Widget _buildTitleRow(BuildContext context, bool watchConnected, WsUiStatusModel wsUiStatus) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('전술 레이더', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        // Watch 연결 indicator
        _ConnectionIndicator(
          icon: Icons.watch_rounded,
          connected: watchConnected,
          label: '워치',
        ),
        const SizedBox(width: 10),
        // WsStatusPill
        WsStatusPill(
          model: wsUiStatus,
          onReconnect: wsUiStatus.showReconnect ? () => ref.read(wsConnectionProvider.notifier).userReconnect() : null,
        ),
      ],
    );
  }

  /// B. 팀 현황 카드 3개 (경찰 수, 남은 도둑, 잡힌 도둑)
  Widget _buildTeamStatusRow(BuildContext context, _TeamStats stats) {
    return Row(
      children: [
        Expanded(
          child: _TeamStatCard(
            icon: Icons.local_police_rounded,
            label: '경찰',
            value: stats.policeCount,
            color: AppColors.borderCyan,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TeamStatCard(
            icon: Icons.directions_run_rounded,
            label: '남은 도둑',
            value: stats.thiefFree,
            color: AppColors.lime,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TeamStatCard(
            icon: Icons.lock_rounded,
            label: '잡힘',
            value: stats.thiefCaptured,
            color: AppColors.red,
          ),
        ),
      ],
    );
  }

  /// 일반 모드: 심박수만 표시
  Widget _buildHeartRateSection(BuildContext context, bool watchConnected) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.favorite_rounded,
            color: watchConnected ? AppColors.red : AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('심박수', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Text(
                watchConnected ? '-- BPM' : '워치 연결 필요',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: watchConnected ? AppColors.textPrimary : AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 팀 현황 계산
  _TeamStats _computeTeamStats(MatchStateDto? match) {
    if (match == null) {
      return const _TeamStats(policeCount: '—', thiefFree: '—', thiefCaptured: '—');
    }

    final score = match.live.score;
    if (score == null) {
      return const _TeamStats(policeCount: '—', thiefFree: '—', thiefCaptured: '—');
    }

    final policeCount = match.teams.police.playerIds.length;
    final totalThief = match.teams.thief.playerIds.length;
    final thiefCaptured = score.thiefCaptured;
    final thiefFree = (totalThief - thiefCaptured).clamp(0, 9999);

    return _TeamStats(
      policeCount: '$policeCount',
      thiefFree: '$thiefFree',
      thiefCaptured: '$thiefCaptured',
    );
  }

  void _mockRadarPing({required WidgetRef ref}) {
    final room = ref.read(roomProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final matchId = ref.read(matchSyncProvider).lastMatchState?.payload.matchId ?? 'MATCH_DEMO';

    if (ref.read(matchSyncProvider).lastMatchState == null) {
      final ms = _buildMockMatchState(room: room, matchId: matchId, serverNowMs: now);
      ref.read(matchSyncProvider.notifier).setMatchState(
            WsEnvelope(
              v: 1,
              type: WsType.matchState,
              matchId: ms.matchId,
              seq: 1,
              ts: now,
              payload: ms,
            ),
          );
    }

    final payload = RadarPingPayload(
      forPlayerId: room.myId.isEmpty ? 'me' : room.myId,
      ttlMs: 7000,
      pings: const [
        RadarPingVector(kind: 'ENEMY', bearingDeg: 25, distanceM: 14, confidence: 0.75),
        RadarPingVector(kind: 'JAIL', bearingDeg: 210, distanceM: 35, confidence: 0.92),
      ],
    );
    final env = WsEnvelope<RadarPingPayload>(
      v: 1,
      type: WsType.radarPing,
      matchId: matchId,
      seq: 2,
      ts: now,
      payload: payload,
    );
    ref.read(matchSyncProvider.notifier).setRadarPing(env);

    final capture = ref.read(matchSyncProvider).lastMatchState?.payload.live.captureProgress?.progress01;
    ref.read(watchRadarVectorProvider.notifier).setLastRadarVector(
          WatchRadarVector(
            headingDeg: 72,
            ttlMs: payload.ttlMs,
            captureProgress01: capture,
            pings: [
              for (final p in payload.pings)
                WatchRadarPing(
                  kind: p.kind,
                  bearingDeg: p.bearingDeg,
                  distanceM: p.distanceM,
                  confidence: p.confidence,
                ),
            ],
          ),
        );
  }

  String _summaryLine({
    required MatchStateDto? match,
    required String myTeam,
    required RadarPingPayload? ping,
  }) {
    final matchId = match?.matchId ?? '—';
    final phase = match?.state ?? '—';
    final pingCount = ping?.pings.length ?? 0;
    final ttl = ping?.ttlMs ?? 0;
    final cap = match?.live.captureProgress?.progress01;
    final capText = (cap == null) ? '—' : cap.toStringAsFixed(2);
    return 'matchId=$matchId / phase=$phase / team=$myTeam / pings=$pingCount / ttlMs=$ttl / capture=$capText';
  }

  MatchStateDto _buildMockMatchState({
    required RoomState room,
    required String matchId,
    required int serverNowMs,
  }) {
    final police = <String>[];
    final thief = <String>[];
    final players = <String, MatchPlayerDto>{};

    for (final m in room.members) {
      final pid = m.id.isEmpty ? 'p_${m.name}' : m.id;
      if (m.team == Team.thief) {
        thief.add(pid);
        players[pid] = MatchPlayerDto(team: 'THIEF', displayName: m.name, status: m.ready ? 'READY' : 'WAIT');
      } else {
        police.add(pid);
        players[pid] = MatchPlayerDto(team: 'POLICE', displayName: m.name, status: m.ready ? 'READY' : 'WAIT');
      }
    }

    return MatchStateDto(
      matchId: matchId,
      state: 'RUNNING',
      mode: 'NORMAL',
      rules: const MatchRulesDto(opponentReveal: OpponentRevealRulesDto(radarPingTtlMs: 7000)),
      time: MatchTimeDto(serverNowMs: serverNowMs, prepEndsAtMs: null, endsAtMs: serverNowMs + 120000),
      teams: MatchTeamsDto(police: TeamPlayersDto(playerIds: police), thief: TeamPlayersDto(playerIds: thief)),
      players: players,
      live: MatchLiveDto(
        score: const MatchScoreDto(thiefFree: 1, thiefCaptured: 3),
        captureProgress: const CaptureProgressDto(
          targetId: 'p3',
          byPoliceId: 'p1',
          progress01: 0.72,
          nearOk: true,
          speedOk: true,
          timeOk: false,
          allOk: false,
          allOkSinceMs: 0,
          lastUpdateMs: 0,
        ),
        rescueProgress: const RescueProgressDto(
          byThiefId: 'p4',
          progress01: 0.35,
          sinceMs: 0,
        ),
      ),
      arena: null,
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

/// 팀 현황 데이터
class _TeamStats {
  final String policeCount;
  final String thiefFree;
  final String thiefCaptured;

  const _TeamStats({
    required this.policeCount,
    required this.thiefFree,
    required this.thiefCaptured,
  });
}

/// Watch 연결 지표
class _ConnectionIndicator extends StatelessWidget {
  final IconData icon;
  final bool connected;
  final String label;

  const _ConnectionIndicator({
    required this.icon,
    required this.connected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.lime : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// 팀 현황 카드 (3개 나란히)
class _TeamStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TeamStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      neonColor: color,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
