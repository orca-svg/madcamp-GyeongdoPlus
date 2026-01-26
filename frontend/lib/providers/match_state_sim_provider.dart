import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/match/match_state_model.dart';
import 'game_phase_provider.dart';
import 'match_rules_provider.dart';

final matchStateSimProvider =
    NotifierProvider<MatchStateSimController, MatchStateSnapshot?>(
      MatchStateSimController.new,
    );

class MatchStateSimController extends Notifier<MatchStateSnapshot?> {
  static const _tick = Duration(seconds: 1);
  static const _captureMinSec = 10;
  static const _captureMaxSec = 14;
  static const _rescueSec = 8;

  final _rand = Random();
  Timer? _timer;

  int _serverNowMs = 0;
  int _endsAtMs = 0;
  int _noticeSeq = 0;

  double _capP = 0;
  int _capTotalTicks = 12;
  bool _nearOk = true;
  bool _speedOk = true;
  bool _timeOk = true;
  int _capStallTicks = 0;

  double? _rescueP;
  int _rescueTick = 0;

  @override
  MatchStateSnapshot? build() {
    ref.onDispose(stop);

    ref.listen<GamePhase>(gamePhaseProvider, (prev, next) {
      if (next == GamePhase.inGame) {
        start();
      } else {
        stop();
      }
    });

    return null;
  }

  void start() {
    if (_timer != null) return;

    final rules = ref.read(matchRulesProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    _serverNowMs = now;
    _endsAtMs = now + (rules.timeLimitSec.clamp(300, 1800) * 1000);

    _capP = 0;
    _capTotalTicks = _captureMinSec + _rand.nextInt(_captureMaxSec - _captureMinSec + 1);
    _nearOk = true;
    _speedOk = true;
    _timeOk = true;
    _capStallTicks = 0;
    _rescueP = null;
    _rescueTick = 0;

    state = MatchStateSnapshot(
      state: 'RUNNING',
      mode: rules.gameMode.wire,
      time: MatchTimeSnapshot(serverNowMs: _serverNowMs, prepEndsAtMs: null, endsAtMs: _endsAtMs),
      live: const MatchLiveSnapshot(
        score: MatchScoreSnapshot(thiefFree: 3, thiefCaptured: 0),
        captureProgress: null,
        rescueProgress: null,
      ),
      noticeSeq: 0,
      noticeMessage: null,
    );

    _timer = Timer.periodic(_tick, (_) => _tickOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }

  void _tickOnce() {
    final cur = state;
    if (cur == null) return;

    _serverNowMs += _tick.inMilliseconds;
    final remainingMs = _endsAtMs - _serverNowMs;

    if (remainingMs <= 0) {
      state = cur.copyWith(
        state: 'ENDED',
        time: cur.time.copyWith(serverNowMs: _serverNowMs, endsAtMs: _endsAtMs),
      );
      stop();
      return;
    }

    // Gate toggles + stall/decay behavior.
    final t = (_serverNowMs ~/ 1000);
    if (t % 5 == 0) _nearOk = _rand.nextBool();
    if (t % 7 == 0) _speedOk = _rand.nextBool();
    if (t % 9 == 0) _timeOk = _rand.nextBool();

    final okNow = _nearOk && _speedOk && _timeOk;
    if (okNow) {
      _capP += 1 / _capTotalTicks;
      _capStallTicks = 0;
    } else {
      _capStallTicks += 1;
      if (_capStallTicks >= 2) {
        _capP = max(0.0, _capP - 0.04);
      }
    }
    _capP = _capP.clamp(0.0, 1.0);

    // Rescue appears occasionally while there are captured thieves.
    final score = cur.live.score;
    if (_rescueP == null && score.thiefCaptured > 0 && t % 23 == 0) {
      _rescueP = 0.0;
      _rescueTick = 0;
    }
    if (_rescueP != null) {
      _rescueTick += 1;
      _rescueP = (_rescueTick / _rescueSec).clamp(0.0, 1.0);
      if (_rescueP! >= 1.0) {
        _rescueP = null;
        _rescueTick = 0;
      }
    }

    final cap = CaptureProgressSnapshot(
      progress01: _capP,
      nearOk: _nearOk,
      speedOk: _speedOk,
      timeOk: _timeOk,
      allOk: okNow && _capP >= 0.99,
      targetId: 'thief_1',
    );

    RescueProgressSnapshot? rescue;
    if (_rescueP != null) {
      rescue = RescueProgressSnapshot(progress01: _rescueP!, byThiefId: 'thief_2');
    }

    var nextScore = score;
    var noticeMsg = cur.noticeMessage;
    var noticeSeq = cur.noticeSeq;

    // Fake "capture confirmed" when gauge completes.
    if (_capP >= 1.0) {
      _capP = 0;
      _capTotalTicks =
          _captureMinSec + _rand.nextInt(_captureMaxSec - _captureMinSec + 1);
      _nearOk = true;
      _speedOk = true;
      _timeOk = true;
      _capStallTicks = 0;

      if (score.thiefFree > 0) {
        nextScore = score.copyWith(
          thiefFree: max(0, score.thiefFree - 1),
          thiefCaptured: score.thiefCaptured + 1,
        );
        _noticeSeq += 1;
        noticeSeq = _noticeSeq;
        noticeMsg = '체포 확정 (도둑 생존 ${nextScore.thiefFree} / 체포 ${nextScore.thiefCaptured})';
      }
    }

    state = cur.copyWith(
      time: cur.time.copyWith(serverNowMs: _serverNowMs, endsAtMs: _endsAtMs),
      live: cur.live.copyWith(
        score: nextScore,
        captureProgress: cap,
        rescueProgress: rescue,
      ),
      noticeSeq: noticeSeq,
      noticeMessage: noticeMsg,
    );
  }
}

