import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_card.dart';
import '../../../providers/room_provider.dart';
import '../../../../features/game/providers/ability_provider.dart';

class AbilitySelectCard extends ConsumerWidget {
  const AbilitySelectCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final abilityState = ref.watch(abilityProvider);

    // Safety check: if no team assigned, can't select ability
    final myTeam = room.me?.team;
    if (myTeam == null) return const SizedBox.shrink();

    final isPolice = myTeam == Team.police;

    return GlowCard(
      glow: false,
      borderColor: AppColors.outlineLow,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showSelectionSheet(context, ref, isPolice),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    abilityState.type == AbilityType.none
                        ? Icons.add_moderator_outlined
                        : abilityState.type.icon,
                    color: AppColors.borderCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '특수 능력 선택',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      abilityState.type == AbilityType.none
                          ? '능력을 선택해주세요'
                          : abilityState.type.label,
                      style: TextStyle(
                        color: abilityState.type == AbilityType.none
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.outlineLow,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSelectionSheet(BuildContext context, WidgetRef ref, bool isPolice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AbilitySheetContent(isPolice: isPolice),
    );
  }
}

class _AbilitySheetContent extends ConsumerWidget {
  final bool isPolice;

  const _AbilitySheetContent({required this.isPolice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentType = ref.watch(abilityProvider).type;

    final options = AbilityType.values.where((t) {
      if (t == AbilityType.none) return false;
      return isPolice ? t.isPolice : t.isThief;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPolice ? '경찰 능력 선택' : '도둑 능력 선택',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final type = options[i];
                final isSel = type == currentType;

                return InkWell(
                  onTap: () {
                    ref.read(abilityProvider.notifier).setType(type);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.borderCyan.withOpacity(0.1)
                          : AppColors.surface2,
                      border: Border.all(
                        color: isSel
                            ? AppColors.borderCyan
                            : AppColors.outlineLow,
                        width: isSel ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          type.icon,
                          color: isSel
                              ? AppColors.borderCyan
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.label,
                                style: TextStyle(
                                  color: isSel
                                      ? AppColors.borderCyan
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '쿨타임 ${type.defaultCooldown}초',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSel)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.borderCyan,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
