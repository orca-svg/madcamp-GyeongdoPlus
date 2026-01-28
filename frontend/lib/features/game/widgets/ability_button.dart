import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/ability_provider.dart';

class AbilityButton extends StatefulWidget {
  final AbilityState ability;
  final VoidCallback onPressed;

  const AbilityButton({
    super.key,
    required this.ability,
    required this.onPressed,
  });

  @override
  State<AbilityButton> createState() => _AbilityButtonState();
}

class _AbilityButtonState extends State<AbilityButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.ability.type == AbilityType.none) return const SizedBox.shrink();

    final isReady = widget.ability.isReady;
    final isActive = widget.ability.isSkillActive;
    final remain = widget.ability.cooldownRemainSec;
    final total = widget.ability.totalCooldownSec;

    // Colors
    final color = isActive
        ? AppColors.lime
        : isReady
        ? AppColors.borderCyan
        : AppColors.textMuted;

    final label = isActive
        ? '사용 중'
        : isReady
        ? widget.ability.type.label
        : '$remain초';

    final progress = total > 0 ? (total - remain) / total : 1.0;

    return GestureDetector(
      onTapDown: isReady ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isReady
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed();
            }
          : null,
      onTapCancel: isReady ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Circle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface1.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (isReady || isActive)
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),

                  // Progress Indicator
                  if (!isReady && !isActive)
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: progress,
                        color: AppColors.borderCyan.withOpacity(0.5),
                        backgroundColor: Colors.transparent,
                        strokeWidth: 3,
                      ),
                    ),

                  // Active Pulse Ring (Static for now, can animate)
                  if (isActive)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.lime, width: 3),
                      ),
                    ),

                  // Icon & Text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive
                            ? Icons.wifi_tethering
                            : widget.ability.type.icon,
                        color: color,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Debug Speed Indicator (Optional)
            if ((widget.ability.cooldownSpeed) > 1.0 && !isReady)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '심박 가속 x${widget.ability.cooldownSpeed.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
