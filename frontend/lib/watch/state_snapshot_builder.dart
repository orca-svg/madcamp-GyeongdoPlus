import 'dart:math';

import '../features/game/providers/ability_provider.dart';
import '../features/game/providers/item_provider.dart';
import '../features/match/match_state_model.dart';
import '../providers/game_provider.dart';
import '../providers/active_tab_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/game_phase_provider.dart';
import '../providers/match_rules_provider.dart';
import '../providers/match_state_sim_provider.dart';
import '../providers/room_provider.dart';
import 'watch_debug_overrides.dart';

class StateSnapshotBuilder {
  static Map<String, dynamic> build(ProviderRead read) {
    final phase = effectiveWatchPhase(read);
    final rules = read(matchRulesProvider);
    final room = read(roomProvider);
    final sim = read(matchStateSimProvider);
    final auth = read(authProvider);
    final gameState = read(gameProvider);
    final itemState = read(itemProvider);
    final ability = read(abilityProvider);
    final user = auth.user;

    final matchId = room.roomId.isNotEmpty ? room.roomId : 'MATCH_DEMO';

    final team = _teamWire(room.me?.team);

    // gameMode.wire 확장/필드가 있는 프로젝트도 있고 아닌 경우도 있어,
    // string 변환을 최대한 안전하게 처리합니다.
    final mode =
        _safeWire(rules.gameMode) ??
        (sim?.mode != null ? _safeWire(sim!.mode) : null) ??
        'NORMAL';

    final timeRemainSec = _timeRemainSec(
      sim,
      itemState.gameDurationSec > 0 ? itemState.gameDurationSec : rules.timeLimitSec,
      itemState.gameElapsedSec,
      phase,
    );

    final policeCount = room.members.isNotEmpty
        ? room.policeCount
        : rules.policeCount;

    final thiefAlive = (phase == GamePhase.lobby || sim == null)
        ? (room.members.isNotEmpty
              ? room.thiefCount
              : max(0, rules.maxPlayers - rules.policeCount))
        : sim!.live.score.thiefFree;

    final thiefCaptured = sim?.live.score.thiefCaptured ?? 0;

    final rescueRate = _rescueRate(thiefAlive, thiefCaptured);

    final enemyNear = _enemyNear(
      team: team,
      room: room,
      gameState: gameState,
    );

    final allyCount10m = _allyCount10m(
      team: team,
      room: room,
      gameState: gameState,
    );
    final allies = _allies(
      room: room,
      gameState: gameState,
      myHeading: gameState.myPosition?.heading ?? 0.0,
      myLat: gameState.myPosition?.latitude ?? 0.0,
      myLng: gameState.myPosition?.longitude ?? 0.0,
      team: team,
    );

    // Use real user data from AuthProvider
    final nickname = user?.nickname ?? room.me?.name ?? 'PLAYER';
    final policeRank = user?.policeRank ?? 'UNRANKED';
    final thiefRank = user?.thiefRank ?? 'UNRANKED';
    final isReady = room.me?.ready ?? false;

    final payload = <String, dynamic>{
      'phase': _phaseWire(phase),
      'activeTab': read(activeTabWireProvider),
      'team': team,
      'mode': mode,
      'timeRemainSec': timeRemainSec,
      'counts': {
        'police': policeCount,
        'thiefAlive': thiefAlive,
        'thiefCaptured': thiefCaptured,
        'rescueRate': rescueRate,
      },
      // Step 1에서는 실데이터 provider가 확정되지 않았으므로 0으로 고정.
      // 추후 이벤트/트래킹 provider가 생기면 교체합니다.
      'my': <String, dynamic>{
        'distanceM': 0,
        'captures': 0,
        'rescues': 0,
        'escapeSec': 0,
        'hr': ability.currentHeartRate > 0 ? ability.currentHeartRate : null,
        'hrMax': null, // PostGame용 최대 심박수
      },
      // 프로필 정보 (OffGame/Lobby용) - Use real user data
      'profile': {
        'nickname': nickname,
        'policeRank': policeRank,
        'thiefRank': thiefRank,
        'isReady': isReady,
      },
      'rulesLite': {
        'contactMode': _safeWire(rules.contactMode) ?? 'CONTACT',
        'releaseScope': _safeWire(rules.rescueReleaseScope) ?? 'PARTIAL',
        'releaseOrder': _safeWire(rules.rescueReleaseOrder) ?? 'FIFO',
        'jailEnabled': rules.jailEnabled,
        'jailRadiusM': rules.jailRadiusM?.round(),
        'zonePoints': rules.zonePolygon?.length ?? 0,
      },
      'rulesLabel': _buildRulesLabel(rules),
      'nearby': {
        'allyCount10m': allyCount10m,
        'enemyNear': enemyNear,
        'allies': allies,
      },
      // 아이템/능력 모드 확장 포인트 (빈 객체로 시작)
      'modeOptions': <String, dynamic>{},
    };

    return {
      'type': 'STATE_SNAPSHOT',
      'ts': DateTime.now().millisecondsSinceEpoch,
      'matchId': matchId,
      'payload': payload,
    };
  }

  static Map<String, String> _buildRulesLabel(MatchRulesState rules) {
    return {
      'timeLimit': '${(rules.timeLimitSec / 60).round()}분',
      'gameMode': rules.gameMode == GameMode.normal ? '일반 모드' : '아이템 모드',
      'contactMode': rules.contactMode == 'RFID'
          ? 'RFID'
          : (rules.contactMode == 'CONTACT' ? '접촉식' : '비접촉'),
      'releaseScope': rules.rescueReleaseScope == 'ALL' ? '전체 해방' : '부분 해방',
      'jailRadius': '${rules.jailRadiusM?.round() ?? 15}m',
    };
  }

  /// team=THIEF 일 때만 의미가 있으며, enemyDistance<=5m이면 true
  static bool _enemyNear({
    required String team,
    required RoomState room,
    required GameState gameState,
  }) {
    if (team != 'THIEF') return false;
    final myPos = gameState.myPosition;
    if (myPos == null) return false;

    for (final player in gameState.players.values) {
      if (player.userId == room.myId || player.team != 'POLICE') {
        continue;
      }

      final distance = _distanceM(
        myPos.latitude,
        myPos.longitude,
        player.lat,
        player.lng,
      );
      if (distance <= 5.0) {
        return true;
      }
    }
    return false;
  }

  /// 경찰 팀일 때, 10m 이내 아군 수를 간단히 카운트 (워치 AOD/레이더용)
  /// 레이더 kind 네이밍이 프로젝트마다 다를 수 있어 최대한 관대하게 처리합니다.
  static int? _allyCount10m({
    required String team,
    required RoomState room,
    required GameState gameState,
  }) {
    if (team != 'POLICE') return null;
    final myPos = gameState.myPosition;
    if (myPos == null) return null;

    var count = 0;
    for (final player in gameState.players.values) {
      if (player.userId == room.myId || player.team != 'POLICE') {
        continue;
      }

      final distance = _distanceM(
        myPos.latitude,
        myPos.longitude,
        player.lat,
        player.lng,
      );
      if (distance <= 10.0) {
        count++;
      }
    }
    return count;
  }

  static int _timeRemainSec(
    MatchStateSnapshot? sim,
    int fallbackSec,
    int elapsedSec,
    GamePhase phase,
  ) {
    if (sim == null) {
      if (phase != GamePhase.inGame) return fallbackSec;
      return max(0, fallbackSec - elapsedSec);
    }
    final endsAt = sim.time.endsAtMs;
    if (endsAt == null) return fallbackSec;
    final remainMs = max(0, endsAt - sim.time.serverNowMs);
    return (remainMs / 1000).round();
  }

  static double _rescueRate(int thiefAlive, int thiefCaptured) {
    final total = thiefAlive + thiefCaptured;
    if (total <= 0) return 0.0;
    return thiefCaptured / total;
  }

  static String _phaseWire(GamePhase phase) {
    switch (phase) {
      case GamePhase.offGame:
        return 'OFF_GAME';
      case GamePhase.lobby:
        return 'LOBBY';
      case GamePhase.inGame:
        return 'IN_GAME';
      case GamePhase.postGame:
        return 'POST_GAME';
    }
  }

  static String _teamWire(Team? t) {
    switch (t) {
      case Team.police:
        return 'POLICE';
      case Team.thief:
        return 'THIEF';
      default:
        return 'UNKNOWN';
    }
  }

  /// enum / string / 기타 타입을 "WIRE 문자열"로 최대한 안전하게 변환합니다.
  /// - enum이면 마지막 토큰만 추출 후 UPPER_SNAKE로 정규화(간단히 UPPER만)
  static String? _safeWire(Object? v) {
    if (v == null) return null;
    if (v is String) {
      final s = v.trim();
      return s.isEmpty ? null : s;
    }
    final s = v.toString();
    if (s.isEmpty) return null;
    // "EnumType.value" -> "value"
    final last = s.contains('.') ? s.split('.').last : s;
    final cleaned = last.trim();
    if (cleaned.isEmpty) return null;
    return cleaned.toUpperCase();
  }

  /// Calculates nearby allies within 30m for Watch Radar
  static List<Map<String, dynamic>> _allies({
    required RoomState room,
    required GameState gameState,
    required double myHeading,
    required double myLat,
    required double myLng,
    required String team,
  }) {
    // Only reliable In-Game with valid my position
    if (!room.inRoom || myLat == 0.0 || myLng == 0.0) return [];

    final List<Map<String, dynamic>> list = [];
    final myTeamStr = team == 'POLICE' ? 'POLICE' : 'THIEF';

    for (final p in gameState.players.values) {
      if (p.userId == room.myId) continue;
      if (p.team != myTeamStr) continue;

      // Calculate distance (Haversine approx or simple Euclidean for small dist)
      // Using geolocation distance is safer
      final d = _distanceM(myLat, myLng, p.lat, p.lng);
      if (d > 30.0) continue; // 30m range

      // Calculate bearing relative to my Heading
      final absoluteBearing = _bearing(myLat, myLng, p.lat, p.lng);
      var relative = absoluteBearing - myHeading;
      // Normalize to -180 ~ 180
      while (relative <= -180) {
        relative += 360;
      }
      while (relative > 180) {
        relative -= 360;
      }

      list.add({
        'd': double.parse(d.toStringAsFixed(1)),
        'b': double.parse(relative.toStringAsFixed(1)),
        'id': p.userId.length > 4 ? p.userId.substring(0, 4) : p.userId,
      });
    }
    return list;
  }

  static double _distanceM(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _bearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = _degToRad(lng2 - lng1);
    final y = sin(dLng) * cos(_degToRad(lat2));
    final x =
        cos(_degToRad(lat1)) * sin(_degToRad(lat2)) -
        sin(_degToRad(lat1)) * cos(_degToRad(lat2)) * cos(dLng);
    final brng = atan2(y, x);
    return (_radToDeg(brng) + 360) % 360;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / pi);
}
