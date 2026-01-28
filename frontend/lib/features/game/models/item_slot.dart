import 'item_type.dart';

/// Slot status state machine
enum SlotStatus {
  empty, // No item assigned
  ready, // Item ready to use
  cooldown, // Item on cooldown
  active, // Item effect active
}

/// Item slot model
class ItemSlot {
  final int index;
  final ItemType item;
  final SlotStatus status;
  final int cooldownRemainSec;
  final int totalCooldownSec;
  final int effectRemainSec;
  final bool isChoiceSlot; // User can select item for this slot

  const ItemSlot({
    required this.index,
    required this.item,
    required this.status,
    this.cooldownRemainSec = 0,
    this.totalCooldownSec = 0,
    this.effectRemainSec = 0,
    this.isChoiceSlot = false,
  });

  /// Factory for empty slot
  factory ItemSlot.empty(int index) => ItemSlot(
        index: index,
        item: ItemType.none,
        status: SlotStatus.empty,
      );

  /// Cooldown progress (0.0 to 1.0)
  double get cooldownProgress => totalCooldownSec > 0
      ? (totalCooldownSec - cooldownRemainSec) / totalCooldownSec
      : 1.0;

  /// Check if slot can be used
  bool get isUsable => status == SlotStatus.ready && item != ItemType.none;

  ItemSlot copyWith({
    int? index,
    ItemType? item,
    SlotStatus? status,
    int? cooldownRemainSec,
    int? totalCooldownSec,
    int? effectRemainSec,
    bool? isChoiceSlot,
  }) {
    return ItemSlot(
      index: index ?? this.index,
      item: item ?? this.item,
      status: status ?? this.status,
      cooldownRemainSec: cooldownRemainSec ?? this.cooldownRemainSec,
      totalCooldownSec: totalCooldownSec ?? this.totalCooldownSec,
      effectRemainSec: effectRemainSec ?? this.effectRemainSec,
      isChoiceSlot: isChoiceSlot ?? this.isChoiceSlot,
    );
  }
}
