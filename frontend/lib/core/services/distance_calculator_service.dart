import 'dart:collection';
import 'dart:math';

import 'package:geolocator/geolocator.dart';

import '../../providers/game_provider.dart';

enum DistanceSource { ble, gps, unknown }

class PlayerDistance {
  final String userId;
  final double distanceMeters;
  final DistanceSource source;
  final DateTime timestamp;

  const PlayerDistance({
    required this.userId,
    required this.distanceMeters,
    required this.source,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PlayerDistance(userId: $userId, distance: ${distanceMeters.toStringAsFixed(2)}m, source: $source)';
  }
}

class DistanceCalculatorService {
  // Moving average filter: Store last 5 samples per user
  final Map<String, Queue<double>> _distanceHistory = {};
  final Map<String, DateTime> _lastSeenTimestamps = {};

  /// Convert RSSI to distance using path loss model
  /// Formula: RSSI = TxPower - 10*n*log10(d)
  /// Solving for d: d = 10^((TxPower - RSSI) / (10*n))
  ///
  /// [rssi]: Received Signal Strength Indicator in dBm
  /// [txPower]: Transmit power at 1 meter (calibration value), typically -59 dBm for phones
  /// Returns distance in meters
  double rssiToDistance(int rssi, {int txPower = -59}) {
    // Path loss exponent: 2.0 = free space, 2.5-3.0 = indoor environment
    const pathLossExponent = 2.5;

    // Calculate distance
    final distance = pow(10, (txPower - rssi) / (10 * pathLossExponent));

    return distance.toDouble();
  }

  /// Calculate GPS distance between two points using Haversine formula
  /// Returns distance in meters
  double gpsDistance(Position myPos, PlayerState otherPlayer) {
    const earthRadiusM = 6371000.0; // Earth radius in meters

    final lat1Rad = _degToRad(myPos.latitude);
    final lat2Rad = _degToRad(otherPlayer.lat);
    final dLat = _degToRad(otherPlayer.lat - myPos.latitude);
    final dLng = _degToRad(otherPlayer.lng - myPos.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusM * c;
  }

  double _degToRad(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Apply moving average filter to smooth distance readings
  /// Uses a 5-sample window to reduce noise from RSSI/GPS fluctuations
  double applyMovingAverage(String userId, double rawDistance) {
    if (!_distanceHistory.containsKey(userId)) {
      _distanceHistory[userId] = Queue<double>();
    }

    final queue = _distanceHistory[userId]!;
    queue.add(rawDistance);

    // Keep only last 5 samples
    if (queue.length > 5) {
      queue.removeFirst();
    }

    // Update last seen timestamp
    _lastSeenTimestamps[userId] = DateTime.now();

    // Calculate average
    final sum = queue.fold<double>(0.0, (sum, value) => sum + value);
    return sum / queue.length;
  }

  /// Calculate hybrid distance: Prefer BLE over GPS
  ///
  /// Priority:
  /// 1. BLE (if RSSI available) - Most accurate for close range
  /// 2. GPS (if position available) - Fallback for medium/long range
  /// 3. Unknown - No data available
  PlayerDistance calculateDistance({
    required String userId,
    required Map<String, int> bleRssiData,
    required Position? myGpsPosition,
    required Map<String, PlayerState> allPlayers,
  }) {
    // Priority 1: BLE (precise for close range)
    if (bleRssiData.containsKey(userId)) {
      final rssi = bleRssiData[userId]!;
      final rawDist = rssiToDistance(rssi);
      final filtered = applyMovingAverage(userId, rawDist);

      return PlayerDistance(
        userId: userId,
        distanceMeters: filtered,
        source: DistanceSource.ble,
        timestamp: DateTime.now(),
      );
    }

    // Priority 2: GPS (fallback)
    if (myGpsPosition != null && allPlayers.containsKey(userId)) {
      final otherPlayer = allPlayers[userId]!;
      final rawDist = gpsDistance(myGpsPosition, otherPlayer);
      final filtered = applyMovingAverage(userId, rawDist);

      return PlayerDistance(
        userId: userId,
        distanceMeters: filtered,
        source: DistanceSource.gps,
        timestamp: DateTime.now(),
      );
    }

    // No data available
    return PlayerDistance(
      userId: userId,
      distanceMeters: 999.0,
      source: DistanceSource.unknown,
      timestamp: DateTime.now(),
    );
  }

  /// Clean up stale distance history for players who left the game
  /// Call this periodically to prevent memory leaks
  void cleanupStaleHistory() {
    final now = DateTime.now();
    final staleThreshold = const Duration(seconds: 60);

    _distanceHistory.removeWhere((userId, queue) {
      final lastSeen = _lastSeenTimestamps[userId];
      return lastSeen != null &&
          now.difference(lastSeen) > staleThreshold;
    });

    _lastSeenTimestamps.removeWhere((userId, timestamp) {
      return now.difference(timestamp) > staleThreshold;
    });
  }
}
