import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../haptics/haptics.dart';
import '../../net/ws/builders/ws_builders.dart';
import '../../providers/game_provider.dart';
import '../../providers/room_provider.dart';
import '../../net/ws/ws_client_provider.dart';
import '../../providers/watch_provider.dart';
import '../../services/watch_sync_service.dart';
import 'ble_proximity_service.dart';
import 'distance_calculator_service.dart';

class ProximityZone {
  static const extreme = 1.0; // 1m - Heartbeat zone
  static const close = 3.0; // 3m - Arrest zone
  static const medium = 5.0; // 5m - Warning zone
}

class InteractionState {
  final Map<String, PlayerDistance> distances;
  final Map<String, DateTime?> captureTimers;
  final Set<String> activeZoneAlerts;
  final Map<String, DateTime> ignoredEnemiesUntil; // For post-arrest cooldown

  const InteractionState({
    required this.distances,
    required this.captureTimers,
    required this.activeZoneAlerts,
    required this.ignoredEnemiesUntil,
  });

  factory InteractionState.initial() => const InteractionState(
    distances: {},
    captureTimers: {},
    activeZoneAlerts: {},
    ignoredEnemiesUntil: {},
  );

  InteractionState copyWith({
    Map<String, PlayerDistance>? distances,
    Map<String, DateTime?>? captureTimers,
    Set<String>? activeZoneAlerts,
    Map<String, DateTime>? ignoredEnemiesUntil,
  }) {
    return InteractionState(
      distances: distances ?? this.distances,
      captureTimers: captureTimers ?? this.captureTimers,
      activeZoneAlerts: activeZoneAlerts ?? this.activeZoneAlerts,
      ignoredEnemiesUntil: ignoredEnemiesUntil ?? this.ignoredEnemiesUntil,
    );
  }
}

class InteractionService {
  final BleProximityService _bleService;
  final DistanceCalculatorService _distanceCalc;
  final Ref _ref;

  Timer? _updateTimer;
  InteractionState _state = InteractionState.initial();

  // Haptic cooldown: userId -> last haptic time
  final Map<String, DateTime> _hapticCooldowns = {};

  InteractionService({
    required BleProximityService bleService,
    required DistanceCalculatorService distanceCalc,
    required Ref ref,
  }) : _bleService = bleService,
       _distanceCalc = distanceCalc,
       _ref = ref;

  /// Start the interaction service
  Future<void> start() async {
    debugPrint('[INTERACTION] Starting service...');

    // 1. Check permissions
    final hasPermissions = await _bleService.checkPermissions();
    if (!hasPermissions) {
      debugPrint('[INTERACTION] BLE permissions not granted, requesting...');
      final granted = await _bleService.requestPermissions();
      if (!granted) {
        debugPrint('[INTERACTION] BLE denied, GPS-only mode');
      } else {
        debugPrint('[INTERACTION] BLE permissions granted');
      }
    } else {
      debugPrint('[INTERACTION] BLE permissions already granted');
    }

    // 2. Start BLE advertising and scanning
    final advStarted = await _bleService.startAdvertising();
    if (advStarted) {
      debugPrint('[INTERACTION] BLE advertising started');
    } else {
      debugPrint(
        '[INTERACTION] BLE advertising failed (may require platform channel)',
      );
    }

    final scanStarted = await _bleService.startScanning();
    if (scanStarted) {
      debugPrint('[INTERACTION] BLE scanning started');
    } else {
      debugPrint('[INTERACTION] BLE scanning failed, GPS-only mode');
    }

    // 3. Start tick timer (500ms intervals)
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _tick();
    });

    debugPrint('[INTERACTION] Service started successfully');
  }

  /// Stop the interaction service
  Future<void> stop() async {
    debugPrint('[INTERACTION] Stopping service...');

    _updateTimer?.cancel();
    _updateTimer = null;

    await _bleService.stopScanning();
    await _bleService.stopAdvertising();

    _state = InteractionState.initial();
    _hapticCooldowns.clear();

    debugPrint('[INTERACTION] Service stopped');
  }

  /// Main tick loop - runs every 500ms
  Future<void> _tick() async {
    try {
      // 1. Get current game state
      final gameState = _ref.read(gameProvider);
      final roomState = _ref.read(roomProvider);
      final myTeam = roomState.me?.team;

      // Only police can arrest
      if (myTeam != Team.police) {
        return;
      }

      // 2. Get BLE RSSI snapshot
      final bleRssi = _bleService.currentRssiSnapshot();

      // 3. Calculate distances to all enemies
      final enemies = gameState.players.values.where((p) {
        final isEnemy = p.team == 'THIEF';
        return isEnemy;
      }).toList();

      final distances = <String, PlayerDistance>{};
      for (final enemy in enemies) {
        // Skip if this enemy is in post-arrest cooldown
        if (_isEnemyIgnored(enemy.userId)) {
          continue;
        }

        distances[enemy.userId] = _distanceCalc.calculateDistance(
          userId: enemy.userId,
          bleRssiData: bleRssi,
          myGpsPosition: gameState.myPosition,
          allPlayers: gameState.players,
        );
      }

      _state = _state.copyWith(distances: distances);

      // 4. Update proximity zones and trigger haptics
      _updateProximityZones(distances);

      // 5. Check auto-arrest conditions
      for (final entry in distances.entries) {
        await _checkAutoArrest(entry.key, entry.value.distanceMeters);
      }

      // 6. Clean up stale data periodically (every ~10 seconds)
      if (DateTime.now().millisecondsSinceEpoch % 10000 < 500) {
        _distanceCalc.cleanupStaleHistory();
        _cleanupIgnoredEnemies();
      }
    } catch (e) {
      debugPrint('[INTERACTION] Tick error: $e');
    }
  }

  /// Check if enemy is in post-arrest cooldown
  bool _isEnemyIgnored(String enemyId) {
    if (!_state.ignoredEnemiesUntil.containsKey(enemyId)) {
      return false;
    }

    final ignoreUntil = _state.ignoredEnemiesUntil[enemyId]!;
    if (DateTime.now().isAfter(ignoreUntil)) {
      // Cooldown expired, remove from ignore list
      final newIgnored = Map<String, DateTime>.from(_state.ignoredEnemiesUntil);
      newIgnored.remove(enemyId);
      _state = _state.copyWith(ignoredEnemiesUntil: newIgnored);
      return false;
    }

    return true;
  }

  /// Clean up expired ignore entries
  void _cleanupIgnoredEnemies() {
    final now = DateTime.now();
    final newIgnored = Map<String, DateTime>.from(_state.ignoredEnemiesUntil);

    newIgnored.removeWhere((enemyId, ignoreUntil) {
      return now.isAfter(ignoreUntil);
    });

    if (newIgnored.length != _state.ignoredEnemiesUntil.length) {
      _state = _state.copyWith(ignoredEnemiesUntil: newIgnored);
    }
  }

  /// Update proximity zones and trigger haptics with cooldown
  void _updateProximityZones(Map<String, PlayerDistance> distances) {
    final roomState = _ref.read(roomProvider);
    final myTeam = roomState.me?.team;

    // Rule: Police get NO proximity vibration (unless item used, handled elsewhere)
    if (myTeam == Team.police) {
      return;
    }

    // Find the closest enemy
    double? closestDistance;
    String? closestEnemy;

    for (final entry in distances.entries) {
      final dist = entry.value.distanceMeters;
      if (closestDistance == null || dist < closestDistance) {
        closestDistance = dist;
        closestEnemy = entry.key;
      }
    }

    if (closestDistance != null && closestEnemy != null) {
      // Rule: Thief gets vibration only if Police is within 15m
      if (closestDistance > 15.0) {
        return;
      }

      HapticPattern? pattern;
      if (closestDistance < ProximityZone.extreme) {
        pattern = HapticPattern.proximityExtreme; // 1m
      } else if (closestDistance < ProximityZone.close) {
        pattern = HapticPattern.proximityClose; // 3m
      } else if (closestDistance < 5.0) {
        pattern = HapticPattern.proximityMedium; // 5m
      } else {
        // 5m ~ 15m: Heartbeat / Warning
        pattern = HapticPattern.warning;
      }

      // pattern is guaranteed by logic
      if (_canTriggerHaptic(closestEnemy)) {
        _triggerHapticWithRouting(pattern);
        _hapticCooldowns[closestEnemy] = DateTime.now();
      }
    }
  }

  Future<void> _triggerHapticWithRouting(HapticPattern pattern) async {
    final isWatchConnected = _ref.read(watchConnectedProvider);

    if (isWatchConnected) {
      // Route to Watch
      final hapticType = _patternToWatchType(pattern);
      // debugPrint('[INTERACTION] Routing haptic $pattern to Watch');
      await _ref.read(watchSyncServiceProvider).sendHapticCommand({
        'type': 'HAPTIC_COMMAND',
        'ts': DateTime.now().millisecondsSinceEpoch,
        'payload': {
          'intensity': hapticType, // 'HEAVY' | 'MEDIUM' | 'LIGHT'
          'pattern': pattern.name,
        },
      });
      // Rule: If Watch connected, Phone is SILENT.
    } else {
      // Fallback to Phone
      // debugPrint('[INTERACTION] Playing haptic $pattern on Phone');
      await Haptics.pattern(pattern);
    }
  }

  String _patternToWatchType(HapticPattern pattern) {
    switch (pattern) {
      case HapticPattern.proximityExtreme:
      case HapticPattern.captureConfirmed:
        return 'HEAVY';
      case HapticPattern.proximityClose:
      case HapticPattern.rescueSuccess:
        return 'MEDIUM';
      case HapticPattern.proximityMedium:
      case HapticPattern.warning:
      default:
        return 'LIGHT';
    }
  }

  /// Check if enough time has passed since last haptic for this user
  /// Cooldown: 5 seconds
  bool _canTriggerHaptic(String userId) {
    if (!_hapticCooldowns.containsKey(userId)) {
      return true;
    }

    final lastTime = _hapticCooldowns[userId]!;
    const cooldownDuration = Duration(seconds: 5);

    return DateTime.now().difference(lastTime) >= cooldownDuration;
  }

  /// Check auto-arrest condition: < 3m for 2+ seconds
  Future<void> _checkAutoArrest(String enemyId, double distance) async {
    final captureTimers = Map<String, DateTime?>.from(_state.captureTimers);

    // Entry condition: < 3m
    if (distance < ProximityZone.close) {
      if (!captureTimers.containsKey(enemyId)) {
        // First entry into arrest zone - start timer
        captureTimers[enemyId] = DateTime.now();
        _state = _state.copyWith(captureTimers: captureTimers);

        debugPrint(
          '[AUTO-ARREST] $enemyId entered 3m zone at ${distance.toStringAsFixed(2)}m, timer started',
        );
      } else {
        // Check dwell time
        final enteredAt = captureTimers[enemyId]!;
        final dwellTime = DateTime.now().difference(enteredAt);

        if (dwellTime.inSeconds >= 2) {
          debugPrint(
            '[AUTO-ARREST] $enemyId arrest triggered after ${dwellTime.inSeconds}s dwell at ${distance.toStringAsFixed(2)}m',
          );

          // Execute arrest
          await _executeArrest(enemyId);

          // Clear timer
          captureTimers.remove(enemyId);
          _state = _state.copyWith(captureTimers: captureTimers);
        }
      }
    } else {
      // Exit condition: left zone before 2s
      if (captureTimers.containsKey(enemyId)) {
        final enteredAt = captureTimers[enemyId]!;
        final dwellTime = DateTime.now().difference(enteredAt);

        debugPrint(
          '[AUTO-ARREST] $enemyId left 3m zone after ${dwellTime.inSeconds}s (now ${distance.toStringAsFixed(2)}m), timer reset',
        );

        captureTimers.remove(enemyId);
        _state = _state.copyWith(captureTimers: captureTimers);
      }
    }
  }

  /// Execute arrest via WebSocket CONFIRM_CAPTURE action
  Future<void> _executeArrest(String enemyId) async {
    try {
      final roomState = _ref.read(roomProvider);
      final wsClient = _ref.read(wsClientProvider);

      // 1. Trigger arrest haptic
      await Haptics.pattern(HapticPattern.captureConfirmed);

      // 2. Send WebSocket CONFIRM_CAPTURE action
      final envelope = buildConfirmCapture(
        matchId: roomState.roomId,
        playerId: roomState.myId,
        targetId: enemyId,
        reason:
            'AUTO_BLE', // Indicate this was an automatic BLE-triggered arrest
      );

      wsClient.sendEnvelope(envelope, (p) => p);

      debugPrint(
        '[AUTO-ARREST] ✅ Sent CONFIRM_CAPTURE for $enemyId (reason: AUTO_BLE)',
      );

      // 3. Add enemy to ignore list for 5 seconds (prevent duplicate arrests)
      final newIgnored = Map<String, DateTime>.from(_state.ignoredEnemiesUntil);
      newIgnored[enemyId] = DateTime.now().add(const Duration(seconds: 5));
      _state = _state.copyWith(ignoredEnemiesUntil: newIgnored);

      debugPrint('[AUTO-ARREST] Ignoring $enemyId for 5 seconds');
    } catch (e) {
      debugPrint('[AUTO-ARREST] ❌ Exception: $e');
    }
  }

  /// Get current state (for debugging)
  InteractionState get state => _state;
}
