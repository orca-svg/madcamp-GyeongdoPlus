import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ability_provider.dart';
import '../../../core/theme/app_colors.dart';

class SkillButton extends ConsumerWidget {
  const SkillButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ability = ref.watch(abilityProvider);
    if (ability.type == AbilityType.none) return const SizedBox.shrink();

    final ratio = ability.totalCooldownSec > 0
        ? (1.0 - (ability.cooldownRemainSec / ability.totalCooldownSec))
        : 1.0;

    return GestureDetector(
      onTap: ability.isReady
          ? () => ref.read(abilityProvider.notifier).useSkill()
          : null,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ability.isReady
              ? AppColors.surface2.withOpacity(0.4)
              : Colors.black.withOpacity(0.6),
          border: Border.all(
            color: ability.isReady
                ? AppColors.borderCyan
                : Colors.grey.withOpacity(0.5),
            width: ability.isReady ? 2 : 1,
          ),
          boxShadow: ability.isReady
              ? [
                  BoxShadow(
                    color: AppColors.borderCyan.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!ability.isReady)
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: ratio,
                  color: AppColors.borderCyan,
                  strokeWidth: 4,
                  backgroundColor: Colors.white10,
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ability.type.icon,
                  color: ability.isReady ? Colors.white : Colors.white38,
                  size: 28,
                ),
                if (!ability.isReady)
                  Text(
                    '${ability.cooldownRemainSec}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      ability.type.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
