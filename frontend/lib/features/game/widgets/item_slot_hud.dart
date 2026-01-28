import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/room_provider.dart';
import '../providers/item_provider.dart';
import 'item_slot_button.dart';
import 'item_select_modal.dart';

class ItemSlotHUD extends ConsumerWidget {
  const ItemSlotHUD({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemState = ref.watch(itemProvider);
    final room = ref.watch(roomProvider);

    if (itemState.slots.isEmpty) return const SizedBox.shrink();

    final myTeam = room.me?.team;
    if (myTeam == null) return const SizedBox.shrink();

    final borderColor =
        myTeam == Team.police ? AppColors.borderCyan : AppColors.red;

    // Show choice modal if pending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (itemState.pendingChoiceModal) {
        _showSelectModal(context, ref, myTeam);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // EMP status indicator
        if (itemState.empActive)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.purple, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flash_off,
                  color: AppColors.purple,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'EMP 활성',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Item slots
        Row(
          children: [
            for (var i = 0; i < itemState.maxSlots; i++)
              Padding(
                padding: EdgeInsets.only(right: i < itemState.maxSlots - 1 ? 8 : 0),
                child: i < itemState.slots.length
                    ? ItemSlotButton(
                        slot: itemState.slots[i],
                        borderColor: borderColor,
                        empBlocked: itemState.empActive && myTeam == Team.police,
                        onTap: () {
                          ref.read(itemProvider.notifier).useItem(i);
                        },
                      )
                    : ItemSlotButton(
                        slot: itemState.slots.firstWhere(
                          (s) => s.index == i,
                          orElse: () => itemState.slots[0],
                        ),
                        borderColor: borderColor,
                      ),
              ),
          ],
        ),
      ],
    );
  }

  void _showSelectModal(BuildContext context, WidgetRef ref, Team team) {
    ref.read(itemProvider.notifier).clearPendingModal();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ItemSelectModal(team: team),
    );
  }
}
