import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/dto/game_dto.dart';

import '../net/socket/socket_io_client_provider.dart';
import 'room_provider.dart';
import 'app_providers.dart'; // for gameRepositoryProvider
import '../watch/watch_sync_controller.dart';
import '../features/game/providers/ability_provider.dart';
import 'interaction_service_provider.dart';
import '../core/services/interaction_service.dart';

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
  });

  PlayerState copyWith({
    double? lat,
    double? lng,
    String? team,
    double? heading,
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

  Future<void> startGame() async {
    // 1. Check permissions
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) {
        debugPrint('[GAME] Location permission denied');
        return;
      }
    }

    // 2. Start Stream
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // Minimal distance to update local UI
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onLocationUpdate);

    // 3. Start InteractionService (BLE auto-arrest)
    _interactionService = ref.read(interactionServiceProvider);
    await _interactionService?.start();

    state = state.copyWith(isTracking: true);
    debugPrint('[GAME] Started location tracking + BLE interaction');
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
