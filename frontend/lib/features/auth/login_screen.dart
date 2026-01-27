import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {

  @override
  Widget build(BuildContext context) {
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
                        '로그인',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _KakaoButton(
                        busy: busy,
                        onPressed: () {
                          // TODO: Implement real Kakao SDK integration
                          // For now, show message
                          showAppSnackBar(
                            context,
                            message: '카카오 로그인 연동 중입니다. 잠시만 기다려주세요.',
                            isError: true,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '카카오 SDK 연동 후 로그인이 활성화됩니다.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
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
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await ref.read(authProvider.notifier).signOut();
                                if (!context.mounted) return;
                                showAppSnackBar(context, message: '로그아웃 완료');
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

class _KakaoButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;

  const _KakaoButton({required this.busy, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: const Color(0xD9191919), // #191919 with 85% opacity
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xD9191919),
                      ),
                    ),
                  )
                : const Icon(Icons.chat_bubble, size: 20),
            const SizedBox(width: 8),
            Text(
              busy ? '로그인 중...' : '카카오 로그인',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
