import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/ble_proximity_service.dart';
import '../core/services/distance_calculator_service.dart';
import '../core/services/interaction_service.dart';
import 'room_provider.dart';

/// Provider for BLE proximity service
/// Automatically rebuilds when room state changes to update participant list
final bleProximityServiceProvider = Provider<BleProximityService>((ref) {
  final roomState = ref.watch(roomProvider);
  final myUserId = roomState.myId;
  final participantIds = roomState.members.map((m) => m.id).toList();

  return BleProximityService(
    myUserId: myUserId,
    gameParticipantIds: participantIds,
  );
});

/// Provider for distance calculator service
final distanceCalculatorServiceProvider =
    Provider<DistanceCalculatorService>((ref) {
  return DistanceCalculatorService();
});

/// Provider for interaction service (auto-arrest engine)
final interactionServiceProvider = Provider<InteractionService>((ref) {
  final bleService = ref.watch(bleProximityServiceProvider);
  final distanceCalc = ref.watch(distanceCalculatorServiceProvider);

  return InteractionService(
    bleService: bleService,
    distanceCalc: distanceCalc,
    ref: ref,
  );
});
