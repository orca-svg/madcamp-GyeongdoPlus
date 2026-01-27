import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/match_rules_provider.dart';

class GameRulesOverlay extends StatelessWidget {
  final MatchRulesState rules;
  final VoidCallback onClose;

  const GameRulesOverlay({
    super.key,
    required this.rules,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.7),
      child: InkWell(
        onTap: onClose,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.outlineLow),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '게임 규칙',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.outlineLow),
                const SizedBox(height: 12),
                _row('맵', rules.mapName),
                _row('제한 시간', '${(rules.timeLimitSec / 60).round()}분'),
                _row('최대 인원', '${rules.maxPlayers}명'),
                _row(
                  '경찰 / 도둑',
                  '${rules.policeCount} / ${rules.maxPlayers - rules.policeCount}',
                ),
                _row('모드', rules.gameMode.label),
                _row('감옥', rules.jailEnabled ? '사용' : '미사용'),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '화면을 터치하여 닫기',
                    style: TextStyle(
                      color: AppColors.textMuted.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
