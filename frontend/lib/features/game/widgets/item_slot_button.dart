import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/item_slot.dart';

class ItemSlotButton extends StatelessWidget {
  final ItemSlot slot;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool empBlocked;

  const ItemSlotButton({
    super.key,
    required this.slot,
    required this.borderColor,
    this.onTap,
    this.empBlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = slot.status == SlotStatus.empty;
    final isReady = slot.status == SlotStatus.ready;
    final isCooldown = slot.status == SlotStatus.cooldown;
    final isActive = slot.status == SlotStatus.active;

    return GestureDetector(
      onTap: (isReady && !empBlocked) ? onTap : null,
      child: SizedBox(
        width: 60,
        height: 60,
        child: Stack(
          children: [
            // Base container
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface1.withOpacity(isEmpty ? 0.3 : 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? AppColors.lime
                      : isEmpty
                          ? borderColor.withOpacity(0.3)
                          : borderColor,
                  width: isActive ? 2.5 : 2,
                  style: isEmpty ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: isEmpty
                  ? Center(
                      child: Icon(
                        Icons.lock_outline,
                        color: AppColors.textSecondary.withOpacity(0.5),
                        size: 24,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8),
                      child: Opacity(
                        opacity: empBlocked ? 0.3 : 1.0,
                        child: Image.asset(
                          slot.item.assetPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
            ),

            // Cooldown overlay
            if (isCooldown)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Progress indicator
                      Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: slot.cooldownProgress,
                            strokeWidth: 3,
                            color: borderColor,
                            backgroundColor: borderColor.withOpacity(0.2),
                          ),
                        ),
                      ),
                      // Remaining seconds
                      Center(
                        child: Text(
                          '${slot.cooldownRemainSec}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Active effect badge
            if (isActive)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${slot.effectRemainSec}s',
                    style: const TextStyle(
                      color: AppColors.surface1,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // EMP blocked overlay
            if (empBlocked && !isEmpty)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.block,
                      color: AppColors.purple,
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
