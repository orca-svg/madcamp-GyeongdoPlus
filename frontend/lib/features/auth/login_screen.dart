import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final busy = auth.status == AuthStatus.signingIn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('로그인'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: GlassBackground(
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GlowCard(
                  glow: false,
                  borderColor: AppColors.outlineLow,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '카카오로 시작하기',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '로그인은 다음 단계에서 실제 연동됩니다.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GradientButton(
                        variant: GradientButtonVariant.joinRoom,
                        title: busy ? '로그인 중...' : '카카오 로그인',
                        height: 56,
                        borderRadius: 16,
                        onPressed: busy
                            ? null
                            : () async {
                                await ref
                                    .read(authProvider.notifier)
                                    .signInWithKakaoStub();
                                if (!context.mounted) return;
                                Navigator.of(context).pop(true);
                              },
                        leading: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.chat_bubble_rounded,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '이 단계에서는 더미 토큰만 저장합니다.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (auth.status == AuthStatus.signedIn) ...[
                        const Divider(color: AppColors.outlineLow, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '현재: ${auth.displayName ?? '익명'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await ref.read(authProvider.notifier).signOut();
                                if (!context.mounted) return;
                                showAppSnackBar(
                                  context,
                                  message: '로그아웃 완료',
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.red,
                              ),
                              child: const Text('로그아웃'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppDimens.padding16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
