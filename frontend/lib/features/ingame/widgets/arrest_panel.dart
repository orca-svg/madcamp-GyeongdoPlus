import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class ArrestPanel extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onArrest;
  final double distanceM; // For debug/display purposes

  const ArrestPanel({
    super.key,
    required this.isEnabled,
    required this.onArrest,
    this.distanceM = 999.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Distance Debug Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '타겟 거리: ${distanceM.toStringAsFixed(1)}m',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Arrest Button
          GestureDetector(
            onTap: isEnabled
                ? () {
                    HapticFeedback.heavyImpact();
                    onArrest();
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 72,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isEnabled ? AppColors.borderCyan : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isEnabled ? Colors.cyanAccent : Colors.grey.shade600,
                  width: 2,
                ),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: AppColors.borderCyan.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.back_hand, // Handcuff-like icon proxy
                    color: isEnabled ? Colors.black : Colors.white38,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEnabled ? '체포하기' : '사거리 밖',
                    style: TextStyle(
                      color: isEnabled ? Colors.black : Colors.white38,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
