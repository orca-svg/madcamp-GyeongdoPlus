// Radar screen: remove overlapping HUD, simplify top row, and refine team status cards.
// Why: avoid UI overlap, keep compact neon layout, and show time + watch indicator cleanly.
// Removes WsStatusPill from the top row as requested.
// Computes remaining time from match time payload (mm:ss) with safe fallback.
// Keeps radar visuals intact while tightening paddings and font sizes.
//
// ✅ Patch for your version
// - Avoid depending on GameMode enum value (GameMode.normal may not exist in your branch)
// - Smooth countdown even when WS time.serverNowMs doesn't update frequently (local delta correction)
// - Prevent setState after dispose
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/connection_indicator.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_card.dart';
import '../../providers/match_mode_provider.dart';
import '../../providers/match_state_sim_provider.dart';
import '../../providers/match_sync_provider.dart';
import '../../providers/radar_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/watch_provider.dart';
import 'widgets/radar_painter.dart';
import '../../watch/watch_sync_controller.dart';
import '../game/widgets/skill_button.dart';
import '../../core/widgets/section_title.dart';
import '../../net/ws/dto/match_state.dart';
import '../../net/ws/dto/radar_ping.dart';
import '../../net/ws/ws_envelope.dart';
import '../../net/ws/ws_client_provider.dart';
import '../../net/ws/ws_types.dart';
import '../../models/game_config.dart';
import '../../providers/game_provider.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  late final Timer _timer;
  double _sweep = 0;

  late final ProviderSubscription<int?> _noticeSub;
  late final ProviderSubscription<dynamic> _matchSub;

  // ✅ countdown smoothing
  int? _endsAtMs;
  int? _lastServerNowMs;
  int? _lastLocalNowMs;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) return;
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

    // ✅ whenever matchState changes, refresh time anchors
    _matchSub = ref.listenManual<dynamic>(
      matchSyncProvider.select((s) => s.lastMatchState),
      (prev, next) {
        final match = next?.payload as MatchStateDto?;
        final time = match?.time;
        if (time == null) return;

        final endsAt = time.endsAtMs;
        if (endsAt == null) return;

        _endsAtMs = endsAt;
        _lastServerNowMs = time.serverNowMs;
        _lastLocalNowMs = DateTime.now().millisecondsSinceEpoch;

        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _noticeSub.close();
    _matchSub.close();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(radarProvider);
    final sync = ref.watch(matchSyncProvider);
    final room = ref.watch(roomProvider);
    final wsConn = ref.watch(wsConnectionProvider);
    final watchConnected = ref.watch(watchConnectedProvider);
    final watchSync = ref.watch(watchSyncControllerProvider);
    final gameMode = ref.watch(currentGameModeProvider);

    final gameState = ref.watch(gameProvider);

    final match = sync.lastMatchState?.payload;
    final ping = sync.lastRadarPing?.payload;

    final myTeam = room.me?.team == Team.thief ? 'THIEF' : 'POLICE';
    final teamStats = _computeTeamStats(gameState);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      floatingActionButton: (gameMode == GameMode.ability)
          ? const Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: SkillButton(),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              18,
              14,
              18,
              AppDimens.bottomBarHIn + 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A. 상단 타이틀 row: 전술 레이더 + 시간 + Watch
                _buildTitleRow(
                  context,
                  watchConnected,
                  _remainingTimeText(match),
                ),
                const SizedBox(height: 12),

                // B. 팀 현황 카드 3개 (레이더 캔버스 상단)
                _buildTeamStatusRow(context, teamStats),
                const SizedBox(height: 14),

                if (kDebugMode) ...[
                  GlowCard(
                    glow: false,
                    borderColor: AppColors.outlineLow,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Text(
                      _summaryLine(match: match, myTeam: myTeam, ping: ping),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
                            child: CustomPaint(
                              painter: RadarPainter(
                                sweep01: _sweep,
                                pings: ui.pings,
                              ),
                            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '방향 미확인 신호',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        for (final p in ui.pings.where((p) => !p.hasBearing))
                          Text(
                            '${p.kind == RadarPingKind.ally ? '아군' : '적'}: ~${p.distanceM.round()}m',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Risk Analysis removed as requested.
                // Only showing Heart Rate if connected.
                _buildHeartRateSection(
                  context,
                  watchConnected,
                  watchSync.currentHeartRate,
                ),

                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      if (kDebugMode) ...[
                        TextButton.icon(
                          onPressed: () =>
                              ref.read(wsConnectionProvider.notifier).connect(),
                          icon: const Icon(Icons.link_rounded, size: 18),
                          label: Text('WS 연결 (${wsConn.status.name})'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => ref
                              .read(wsConnectionProvider.notifier)
                              .disconnect(),
                          icon: const Icon(Icons.link_off_rounded, size: 18),
                          label: const Text('WS 해제'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      TextButton.icon(
                        onPressed: () async {
                          await ref
                              .read(watchConnectedProvider.notifier)
                              .refresh();
                          final ok = ref.read(watchConnectedProvider);
                          if (!context.mounted) return;
                          showAppSnackBar(
                            context,
                            message: 'Watch connected: $ok',
                          );
                        },
                        icon: const Icon(Icons.watch_rounded, size: 18),
                        label: const Text('연결 확인'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                if (kDebugMode && (sync.lastJsonPreview ?? '').isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const SectionTitle(title: '디버그 JSON'),
                  const SizedBox(height: 10),
                  GlowCard(
                    glow: false,
                    borderColor: AppColors.outlineLow,
                    child: SelectableText(
                      sync.lastJsonPreview!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A. 상단 타이틀 row: 전술 레이더 + 시간 + Watch indicator
  Widget _buildTitleRow(
    BuildContext context,
    bool watchConnected,
    String remainText,
  ) {
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
        Text(
          remainText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        ConnectionIndicator(
          icon: Icons.watch_rounded,
          connected: watchConnected,
          label: '워치',
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
        const SizedBox(width: 8),
        Expanded(
          child: _TeamStatCard(
            icon: Icons.directions_run_rounded,
            label: '남은 도둑',
            value: stats.thiefFree,
            color: AppColors.lime,
          ),
        ),
        const SizedBox(width: 8),
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
  Widget _buildHeartRateSection(
    BuildContext context,
    bool watchConnected,
    int? bpm,
  ) {
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
              Text(
                '심박수',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                (watchConnected && bpm != null && bpm > 0)
                    ? '$bpm BPM'
                    : (watchConnected ? '-- BPM' : '워치 연결 필요'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: watchConnected
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 팀 현황 계산 (GameProvider 기반)
  _TeamStats _computeTeamStats(GameState gameState) {
    if (gameState.players.isEmpty) {
      return const _TeamStats(
        policeCount: '—',
        thiefFree: '—',
        thiefCaptured: '—',
      );
    }

    final policeCount = gameState.players.values
        .where((p) => p.team == 'POLICE')
        .length;
    final thiefTotal = gameState.players.values
        .where((p) => p.team == 'THIEF')
        .length;
    final thiefCaptured = gameState.players.values
        .where((p) => p.team == 'THIEF' && p.isArrested)
        .length;
    final thiefFree = (thiefTotal - thiefCaptured).clamp(0, 9999);

    return _TeamStats(
      policeCount: '$policeCount',
      thiefFree: '$thiefFree',
      thiefCaptured: '$thiefCaptured',
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

  /// ✅ remaining time (mm:ss) with smoothing
  String _remainingTimeText(MatchStateDto? match) {
    if (_endsAtMs != null &&
        _lastServerNowMs != null &&
        _lastLocalNowMs != null) {
      final localNow = DateTime.now().millisecondsSinceEpoch;
      final elapsedLocal = localNow - _lastLocalNowMs!;
      final estServerNow = _lastServerNowMs! + elapsedLocal;
      final remainMs = _endsAtMs! - estServerNow;
      final remainSec = (remainMs / 1000).floor();
      if (remainSec <= 0) return '00:00';
      return _fmtMmSs(remainSec);
    }

    final time = match?.time;
    final endsAtMs = time?.endsAtMs;
    if (time == null || endsAtMs == null) return '--:--';
    final nowMs = time.serverNowMs;
    final remainMs = endsAtMs - nowMs;
    final remainSec = (remainMs / 1000).floor();
    if (remainSec <= 0) return '00:00';
    return _fmtMmSs(remainSec);
  }

  String _fmtMmSs(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      radius: 16,
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
