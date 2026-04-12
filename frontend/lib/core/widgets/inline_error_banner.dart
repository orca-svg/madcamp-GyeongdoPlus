import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glow_card.dart';

class InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const InlineErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = '다시 시도',
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glow: false,
      borderColor: AppColors.red.withOpacity(0.45),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppColors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.red,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(retryLabel),
            ),
          ],
        ],
      ),
    );
  }
}
