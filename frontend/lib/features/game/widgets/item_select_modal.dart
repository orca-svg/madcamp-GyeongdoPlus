import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/room_provider.dart';
import '../models/item_type.dart';
import '../providers/item_provider.dart';

class ItemSelectModal extends ConsumerWidget {
  final Team team;

  const ItemSelectModal({super.key, required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ItemType.forTeam(team);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineLow,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '아이템 선택',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: team == Team.police
                        ? AppColors.borderCyan.withOpacity(0.2)
                        : AppColors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: team == Team.police
                          ? AppColors.borderCyan
                          : AppColors.red,
                    ),
                  ),
                  child: Text(
                    team == Team.police ? '경찰' : '도둑',
                    style: TextStyle(
                      color: team == Team.police
                          ? AppColors.borderCyan
                          : AppColors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (final item in items)
                  _ItemCard(
                    item: item,
                    team: team,
                    onTap: () {
                      // Select for next available slot
                      final itemState = ref.read(itemProvider);
                      final slotIndex = itemState.slots.length;
                      ref.read(itemProvider.notifier).selectItem(slotIndex, item);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ItemType item;
  final Team team;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.team,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        team == Team.police ? AppColors.borderCyan : AppColors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image
            SizedBox(
              width: 48,
              height: 48,
              child: Image.asset(
                item.assetPath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            // Label
            Text(
              item.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            // Description tooltip (optional)
            Tooltip(
              message: item.description,
              child: Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
