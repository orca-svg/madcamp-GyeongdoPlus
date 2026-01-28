import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item_slot.dart';
import '../models/item_type.dart';
import '../../../data/dto/game_dto.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/room_provider.dart';
import '../../../net/socket/socket_io_client_provider.dart';
import '../../../core/services/audio_service.dart'; // Audio

/// Item state
class ItemState {
  final List<ItemSlot> slots;
  final int maxSlots;
  final int gameElapsedSec;
  final int gameDurationSec;
  final Team? myTeam;
  final bool empActive;
  final DateTime? empActiveUntil;
  final bool pendingChoiceModal; // Trigger for modal

  const ItemState({
    required this.slots,
    required this.maxSlots,
    required this.gameElapsedSec,
    required this.gameDurationSec,
    required this.myTeam,
    this.empActive = false,
    this.empActiveUntil,
    this.pendingChoiceModal = false,
  });

  factory ItemState.initial() => const ItemState(
    slots: [],
    maxSlots: 0,
    gameElapsedSec: 0,
    gameDurationSec: 0,
    myTeam: null,
  );

  ItemState copyWith({
    List<ItemSlot>? slots,
    int? maxSlots,
    int? gameElapsedSec,
    int? gameDurationSec,
    Team? myTeam,
    bool? empActive,
    DateTime? empActiveUntil,
    bool? pendingChoiceModal,
  }) {
    return ItemState(
      slots: slots ?? this.slots,
      maxSlots: maxSlots ?? this.maxSlots,
      gameElapsedSec: gameElapsedSec ?? this.gameElapsedSec,
      gameDurationSec: gameDurationSec ?? this.gameDurationSec,
      myTeam: myTeam ?? this.myTeam,
      empActive: empActive ?? this.empActive,
      empActiveUntil: empActiveUntil ?? this.empActiveUntil,
      pendingChoiceModal: pendingChoiceModal ?? this.pendingChoiceModal,
    );
  }
}

/// Item controller
class ItemController extends Notifier<ItemState> {
  Timer? _tickTimer;
  final Random _rand = Random();

  @override
  ItemState build() {
    // Listen to socket events
    _listenSocketEvents();
    return ItemState.initial();
  }

  void _listenSocketEvents() {
    final eventStream = ref.read(socketIoClientProvider.notifier).events;
    eventStream.listen((event) {
      switch (event.name) {
        case 'emp_activated':
          _handleEmpActivated(event.payload);
          break;
        case 'radar_activated':
          // Handle radar effect (game_screen will listen)
          break;
        case 'siren_activated':
          // Handle siren effect
          break;
        // Add other item events as needed
      }
    });
  }

  /// Initialize for game start
  void initializeForGame({required int gameDurationSec, required Team myTeam}) {
    debugPrint(
      '[ITEM] Initializing for game: ${gameDurationSec}s, team: $myTeam',
    );

    // Start with 1 slot, grant random item
    final slot0 = ItemSlot.empty(0);
    final randomItem = _getRandomItemForTeam(myTeam);
    final initialSlot = slot0.copyWith(
      item: randomItem,
      status: SlotStatus.ready,
    );

    state = ItemState(
      slots: [initialSlot],
      maxSlots: 1,
      gameElapsedSec: 0,
      gameDurationSec: gameDurationSec,
      myTeam: myTeam,
    );

    // Start tick timer
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    debugPrint('[ITEM] Granted initial item: ${randomItem.label}');
  }

  /// Stop timer
  void stop() {
    _tickTimer?.cancel();
    _tickTimer = null;
    state = ItemState.initial();
    debugPrint('[ITEM] Stopped');
  }

  /// Tick every second
  void _tick() {
    final newElapsed = state.gameElapsedSec + 1;
    var newSlots = List<ItemSlot>.from(state.slots);
    var newMaxSlots = state.maxSlots;

    // Time-based slot expansion
    if (newElapsed == 600 && newMaxSlots < 2) {
      // 10 minutes
      newMaxSlots = 2;
      _grantRandomItem(1, state.myTeam!);
      debugPrint('[ITEM] 10min reached: Slot 1 granted');
    } else if (newElapsed == 900 && newMaxSlots < 2) {
      // 15 minutes - Choice modal
      state = state.copyWith(pendingChoiceModal: true);
      debugPrint('[ITEM] 15min reached: Choice modal triggered');
      return; // User will select
    } else if (newElapsed == 1200 && newMaxSlots < 3) {
      // 20 minutes
      newMaxSlots = 3;
      _grantRandomItem(2, state.myTeam!);
      debugPrint('[ITEM] 20min reached: Slot 2 granted');
    } else if (newElapsed == state.gameDurationSec - 300 && newMaxSlots >= 2) {
      // 5 minutes before end - Emergency choice
      state = state.copyWith(pendingChoiceModal: true);
      debugPrint('[ITEM] 5min remaining: Emergency choice modal triggered');
      return;
    }

    // Update cooldowns and active effects
    for (var i = 0; i < newSlots.length; i++) {
      final slot = newSlots[i];

      // Cooldown countdown
      if (slot.status == SlotStatus.cooldown && slot.cooldownRemainSec > 0) {
        final newRemain = slot.cooldownRemainSec - 1;
        if (newRemain <= 0) {
          newSlots[i] = slot.copyWith(
            status: SlotStatus.ready,
            cooldownRemainSec: 0,
          );
        } else {
          newSlots[i] = slot.copyWith(cooldownRemainSec: newRemain);
        }
      }

      // Active effect countdown
      if (slot.status == SlotStatus.active && slot.effectRemainSec > 0) {
        final newRemain = slot.effectRemainSec - 1;
        if (newRemain <= 0) {
          // Effect expired, enter cooldown
          newSlots[i] = slot.copyWith(
            status: SlotStatus.cooldown,
            effectRemainSec: 0,
            cooldownRemainSec: slot.item.cooldownSec,
            totalCooldownSec: slot.item.cooldownSec,
          );
        } else {
          newSlots[i] = slot.copyWith(effectRemainSec: newRemain);
        }
      }
    }

    // EMP expiration check
    var newEmpActive = state.empActive;
    if (state.empActive && state.empActiveUntil != null) {
      if (DateTime.now().isAfter(state.empActiveUntil!)) {
        newEmpActive = false;
        debugPrint('[ITEM] EMP expired');
      }
    }

    state = state.copyWith(
      gameElapsedSec: newElapsed,
      slots: newSlots,
      maxSlots: newMaxSlots,
      empActive: newEmpActive,
    );
  }

  /// Grant random item to slot
  void _grantRandomItem(int slotIndex, Team team) {
    final randomItem = _getRandomItemForTeam(team);
    final newSlot = ItemSlot(
      index: slotIndex,
      item: randomItem,
      status: SlotStatus.ready,
    );

    final newSlots = List<ItemSlot>.from(state.slots);
    if (slotIndex >= newSlots.length) {
      newSlots.add(newSlot);
    } else {
      newSlots[slotIndex] = newSlot;
    }

    state = state.copyWith(slots: newSlots);
    state = state.copyWith(slots: newSlots);

    // Play SFX
    ref.read(audioServiceProvider).playSfx(AudioType.itemGet);

    debugPrint('[ITEM] Granted ${randomItem.label} to slot $slotIndex');
  }

  /// Select item for a slot (user choice)
  Future<void> selectItem(int slotIndex, ItemType item) async {
    final room = ref.read(roomProvider);
    if (!room.inRoom) return;

    // Validate team
    if (item.team != state.myTeam) {
      debugPrint('[ITEM] Team mismatch: ${item.team} != ${state.myTeam}');
      return;
    }

    // API call
    final repo = ref.read(gameRepositoryProvider);
    final dto = SelectItemDto(matchId: room.roomId, itemId: item.id);

    try {
      final result = await repo.selectItem(dto);
      if (result.success) {
        // Update local state
        final newSlots = List<ItemSlot>.from(state.slots);
        if (slotIndex >= newSlots.length) {
          newSlots.add(
            ItemSlot(index: slotIndex, item: item, status: SlotStatus.ready),
          );
        } else {
          newSlots[slotIndex] = newSlots[slotIndex].copyWith(
            item: item,
            status: SlotStatus.ready,
          );
        }

        state = state.copyWith(slots: newSlots, pendingChoiceModal: false);
        debugPrint('[ITEM] Selected ${item.label} for slot $slotIndex');
      } else {
        debugPrint('[ITEM] Select failed: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('[ITEM] Select exception: $e');
    }
  }

  /// Use item in slot
  Future<void> useItem(int slotIndex) async {
    if (slotIndex >= state.slots.length) return;

    final slot = state.slots[slotIndex];
    if (!slot.isUsable) return;

    // EMP check (police only)
    if (state.myTeam == Team.police && state.empActive) {
      debugPrint('[ITEM] EMP active - cannot use police items');
      return;
    }

    final room = ref.read(roomProvider);
    if (!room.inRoom) return;

    // API call
    final repo = ref.read(gameRepositoryProvider);
    final dto = UseItemDto(matchId: room.roomId, itemId: slot.item.id);

    try {
      final result = await repo.useItem(dto);
      if (result.success) {
        // Execute local effect
        _executeLocalEffect(slot.item);

        // Emit socket event for server-side effects
        _emitItemEffect(slot.item);

        // Update slot status
        final newSlots = List<ItemSlot>.from(state.slots);
        if (slot.item.isInstant) {
          // Instant items go directly to cooldown
          newSlots[slotIndex] = slot.copyWith(
            status: SlotStatus.cooldown,
            cooldownRemainSec: slot.item.cooldownSec,
            totalCooldownSec: slot.item.cooldownSec,
          );
        } else {
          // Duration items become active
          newSlots[slotIndex] = slot.copyWith(
            status: SlotStatus.active,
            effectRemainSec: slot.item.durationSec,
          );
        }

        state = state.copyWith(slots: newSlots);
        debugPrint('[ITEM] Used ${slot.item.label}');
      } else {
        debugPrint('[ITEM] Use failed: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('[ITEM] Use exception: $e');
    }
  }

  /// Execute local-only effects
  void _executeLocalEffect(ItemType item) {
    switch (item) {
      case ItemType.detector:
        // Set flag for InteractionService to use
        debugPrint('[ITEM] Detector activated (local)');
        break;
      case ItemType.siren:
        // Play local siren sound (optional)
        debugPrint('[ITEM] Siren activated (local)');
        break;
      default:
        break;
    }
  }

  /// Emit socket event for server-side effects
  void _emitItemEffect(ItemType item) {
    final socket = ref.read(socketIoClientProvider.notifier);
    final room = ref.read(roomProvider);

    final payload = {'matchId': room.roomId, 'itemId': item.id};

    socket.emit('use_item', payload);
    debugPrint('[ITEM] Emitted use_item: ${item.id}');
  }

  /// Handle EMP activation from socket
  void _handleEmpActivated(Map<String, dynamic> payload) {
    // Only police are affected
    if (state.myTeam != Team.police) return;

    final durationSec = payload['durationSec'] as int? ?? 15;
    state = state.copyWith(
      empActive: true,
      empActiveUntil: DateTime.now().add(Duration(seconds: durationSec)),
    );

    debugPrint(
      '[ITEM] EMP activated - police items disabled for ${durationSec}s',
    );
  }

  /// Clear pending choice modal
  void clearPendingModal() {
    state = state.copyWith(pendingChoiceModal: false);
  }

  /// Get random item for team
  ItemType _getRandomItemForTeam(Team team) {
    final items = ItemType.forTeam(team);
    return items[_rand.nextInt(items.length)];
  }
}

final itemProvider = NotifierProvider<ItemController, ItemState>(
  ItemController.new,
);
