import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/dto/game_dto.dart';

import '../net/socket/socket_io_client_provider.dart';
import 'room_provider.dart';
import 'app_providers.dart'; // for gameRepositoryProvider
import '../watch/watch_sync_controller.dart';
import 'package:flutter/services.dart';
import '../features/game/providers/ability_provider.dart';
import '../features/game/services/interaction_service.dart';
import '../core/services/audio_service.dart'; // Audio

// Simple model for player state in game
class PlayerState {
  final String userId;
  final double lat;
  final double lng;
  final String team; // 'POLICE' | 'THIEF'
  final double? heading;

  const PlayerState({
    required this.userId,
    required this.lat,
    required this.lng,
    required this.team,

    this.heading,
    this.isArrested = false,
  });

  final bool isArrested;

  PlayerState copyWith({
    double? lat,
    double? lng,
    String? team,
    double? heading,
    bool? isArrested,
  }) {
    return PlayerState(
      userId: userId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      team: team ?? this.team,
      heading: heading ?? this.heading,
    );
  }
}

class GameState {
  final bool isTracking;
  final Map<String, PlayerState> players;
  final Position? myPosition;

  const GameState({
    required this.isTracking,
    required this.players,
    this.myPosition,
  });

  factory GameState.initial() =>
      const GameState(isTracking: false, players: {}, myPosition: null);

  GameState copyWith({
    bool? isTracking,
    Map<String, PlayerState>? players,
    Position? myPosition,
  }) {
    return GameState(
      isTracking: isTracking ?? this.isTracking,
      players: players ?? this.players,
      myPosition: myPosition ?? this.myPosition,
    );
  }
}

class GameController extends Notifier<GameState> {
  StreamSubscription<Position>? _positionStream;
  InteractionService? _interactionService;
  DateTime? _lastSentTime;
  static const Duration _throttleDuration = Duration(milliseconds: 1000);

  StreamSubscription<List<DetectedPlayer>>? _bleSubscription;
  Timer? _arrestLoopTimer;
  final Map<String, DetectedPlayer> _lastBleDetections = {};

  // Arrest State
  String? _candidateTargetId;
  int _candidateDurationTicks = 0; // 500ms ticks. 4 ticks = 2s.
  DateTime? _lastHapticTime;

  @override
  GameState build() {
    // Listen to socket events for other players' movements
    _listenSocketEvents();
    return GameState.initial();
  }

  void _listenSocketEvents() {
    final eventStream = ref.read(socketIoClientProvider.notifier).events;
    eventStream.listen((event) {
      if (event.name == 'player_moved') {
        _handlePlayerMoved(event.payload);
      } else if (event.name == 'player_arrested') {
        _handlePlayerArrested(event.payload);
      }
    });
  }

  void _handlePlayerMoved(Map<String, dynamic> payload) {
    try {
      final userId = payload['userId'] as String;
      // Filter out self if echoed back (optional, but good practice)
      final myId = ref.read(roomProvider).myId;
      if (userId == myId) return;

      final lat = (payload['lat'] as num).toDouble();
      final lng = (payload['lng'] as num).toDouble();
      final team = payload['team'] as String? ?? 'THIEF'; // Default fallback
      final heading = (payload['heading'] as num?)?.toDouble();

      final newPlayer = PlayerState(
        userId: userId,
        lat: lat,
        lng: lng,
        team: team,
        heading: heading,
      );

      final newMap = Map<String, PlayerState>.from(state.players);
      newMap[userId] = newPlayer;

      state = state.copyWith(players: newMap);
    } catch (e) {
      debugPrint('[GAME] Player moved parse error: $e');
    }
  }

  void _handlePlayerArrested(Map<String, dynamic> payload) {
    try {
      final victimId = payload['victimId'] as String;
      final arresterId = payload['arresterId'] as String;
      
      debugPrint('[GAME] Player Arrested: $victimId by $arresterId');

      if (state.players.containsKey(victimId)) {
        final p = state.players[victimId]!;
        final newPlayer = p.copyWith(isArrested: true);
        final newMap = Map<String, PlayerState>.from(state.players);
        newMap[victimId] = newPlayer;
        state = state.copyWith(players: newMap);
      }
      
      // Check if self is arrested
      final room = ref.read(roomProvider);
      if (victimId == room.myId) {
        // Trigger Red Vignette via state logic in GameScreen
        // Also play sound
         ref.read(audioServiceProvider).playSfx(AudioType.siren); // or arrestFail
      }
    } catch (e) {
      debugPrint('[GAME] Arrest parse error: $e');
    }
  }

  // Combined Start Method
  Future<void> startGame() async {
    final room = ref.read(roomProvider);
    final myId = room.myId;

    // 1. Check permissions (GPS)
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) {
        debugPrint('[GAME] Location permission denied');
        return;
      }
    }

    // 2. Start GPS Stream
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Higher accuracy for game
      distanceFilter: 0, // Continuous updates for smoothness
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onLocationUpdate);

    // 3. Start BLE Interaction Service
    final interactionService = ref.read(interactionServiceProvider);
    try {
      await interactionService.start(myId);
      _bleSubscription = interactionService.nearbyPlayers.listen((detected) {
        // Update local cache
        for (var d in detected) {
          _lastBleDetections[d.partialId] = d;
        }
      });
    } catch (e) {
      debugPrint('[GAME] BLE Start Error: $e');
    }

    // 4. Start Arrest Loop (500ms)
    _arrestLoopTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkAutoArrest();
    });

    state = state.copyWith(isTracking: true);
    debugPrint('[GAME] Started Game Systems (GPS + BLE)');
  }

  void stopGame() {
    _positionStream?.cancel();
    _positionStream = null;
    // Stop InteractionService
    _interactionService?.stop();
    _interactionService = null;

    state = GameState.initial();
    debugPrint('[GAME] Stopped location tracking + BLE interaction');
  }

  // Auto-Arrest Logic
  void _checkAutoArrest() {
    final room = ref.read(roomProvider);
    if (!room.inRoom || state.myPosition == null) return;

    // Only Police can arrest Thief
    if (room.me?.team != Team.police) return;

    final myPos = state.myPosition!;
    final enemies = state.players.values.where((p) => p.team == 'THIEF');

    double minDistance = 9999.0;
    String? closestEnemyId;

      // CRITICAL FIX: Skip self explicitly
      if (enemy.userId == room.myId) continue;

      // 1. Calculate Hybrid Distance
      double distance = 9999.0;

      // Try BLE First
      final shortId = enemy.userId.length > 8
          ? enemy.userId.substring(0, 8)
          : enemy.userId;
      final bleData = _lastBleDetections[shortId];

      // Use BLE if available and recent (< 3s)
      if (bleData != null &&
          DateTime.now().difference(bleData.timestamp).inSeconds < 3) {
        distance = bleData.distance;
        debugPrint(
          '[GAME] Using BLE Distance for $shortId: ${distance.toStringAsFixed(2)}m',
        );
      } else {
        // Fallback to GPS
        distance = Geolocator.distanceBetween(
          myPos.latitude,
          myPos.longitude,
          enemy.lat,
          enemy.lng,
        );
      }

      if (distance < minDistance) {
        minDistance = distance;
        closestEnemyId = enemy.userId;
      }
    }

    // Logic: 3m Threshold, 2s Duration
    if (closestEnemyId != null && minDistance <= 3.0) {
      if (_candidateTargetId == closestEnemyId) {
        _candidateDurationTicks++;
      } else {
        _candidateTargetId = closestEnemyId;
        _candidateDurationTicks = 1;
      }

      // Feedback during approach/capture
      _provideHapticFeedback(minDistance);

      // Trigger Arrest if duration met (2s = 4 ticks)
      if (_candidateDurationTicks >= 4) {
        _performArrest(closestEnemyId);
        _candidateDurationTicks = 0; // Reset after attempt
      }
    } else {
      // Reset if out of range or target changed
      _candidateTargetId = null;
      _candidateDurationTicks = 0;

      // 5m warning feedback (weak)
      if (minDistance <= 5.0) {
        _provideHapticFeedback(minDistance);
      }
    }
  }

  void _provideHapticFeedback(double distance) {
    final now = DateTime.now();
    if (_lastHapticTime != null &&
        now.difference(_lastHapticTime!).inMilliseconds < 1000) {
      return; // Throttle haptics
    }

    if (distance <= 1.5) {
      HapticFeedback.heavyImpact(); // Close!
    } else if (distance <= 3.0) {
      HapticFeedback.mediumImpact(); // Capture Range
    } else if (distance <= 5.0) {
      HapticFeedback.lightImpact(); // Approach
    }

    _lastHapticTime = now;
  }

  Future<void> _performArrest(String targetId) async {
    debugPrint('[GAME] PERFORMING AUTO-ARREST on $targetId');
    HapticFeedback.vibrate();

    final room = ref.read(roomProvider);
    final repo = ref.read(gameRepositoryProvider);
    try {
      final result = await repo.arrest(room.roomId, targetId);
      if (result.success) {
        debugPrint('[GAME] Arrest Success: ${result.data?.status}');
        // Play SFX
        ref.read(audioServiceProvider).playSfx(AudioType.arrestSuccess);
      } else {
        debugPrint('[GAME] Arrest Failed: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('[GAME] Arrest API Error: $e');
    }
  }

  void _onLocationUpdate(Position position) {
    // 1. Update local state (immediate UI feedback)
    state = state.copyWith(myPosition: position);

    // 2. Network Throttle
    final now = DateTime.now();
    if (_lastSentTime != null &&
        now.difference(_lastSentTime!) < _throttleDuration) {
      return;
    }

    // 3. Send API
    _sendLocation(position);
    _lastSentTime = now;
  }

  Future<void> _sendLocation(Position position) async {
    final room = ref.read(roomProvider);
    if (!room.inRoom) return;

    // Ability Logic: Shadow stops location updates
    final ability = ref.read(abilityProvider);
    if (ability.type == AbilityType.shadow && ability.isSkillActive) {
      debugPrint('[GAME] Shadow Active - Skipping location update');
      return;
    }

    final repo = ref.read(gameRepositoryProvider);

    // Get Heart Rate from Watch if available
    int? heartRate;
    try {
      final watchSync = ref.read(watchSyncControllerProvider);
      heartRate = watchSync.currentHeartRate;
    } catch (e) {
      debugPrint('[GAME] Watch sync unavailable: $e');
    }

    final dto = MoveDto(
      matchId: room.roomId,
      lat: position.latitude,
      lng: position.longitude,
      heartRate: heartRate ?? 0, // Use 0 if watch unavailable
      heading: position.heading,
    );

    try {
      // Fire-and-forget for performance, but log errors
      final result = await repo.move(dto);
      if (!result.success) {
        debugPrint('[GAME] Move failed: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('[GAME] Move exception: $e');
    }
  }
}

final gameProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);
