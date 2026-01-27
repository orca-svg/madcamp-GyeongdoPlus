import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_dimens.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/glass_background.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idCtrl = TextEditingController(text: 'test');
  final _pwCtrl = TextEditingController(text: '12341234');

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

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
                        onPressed: () async {
                          await ref
                              .read(authProvider.notifier)
                              .signInWithKakaoStub();
                          if (!context.mounted) return;
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(true);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '로그인은 다음 단계에서 실제 연동됩니다.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '자체 로그인',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _idCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '아이디',
                          hintText: 'test',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _pwCtrl,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLocalLogin(
                          context: context,
                          ref: ref,
                          id: _idCtrl.text,
                          password: _pwCtrl.text,
                        ),
                        decoration: const InputDecoration(
                          labelText: '비밀번호',
                          hintText: '12341234',
                        ),
                      ),
                      const SizedBox(height: 12),
                      GradientButton(
                        variant: GradientButtonVariant.createRoom,
                        title: busy ? '로그인 중...' : '로그인',
                        height: 56,
                        borderRadius: 16,
                        onPressed: busy
                            ? null
                            : () => _handleLocalLogin(
                                context: context,
                                ref: ref,
                                id: _idCtrl.text,
                                password: _pwCtrl.text,
                              ),
                        leading: busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            showAppSnackBar(
                              context,
                              message: '회원가입은 다음 단계에서 연결됩니다',
                              isError: true,
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.borderCyan,
                          ),
                          child: const Text('회원가입'),
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

  Future<void> _handleLocalLogin({
    required BuildContext context,
    required WidgetRef ref,
    required String id,
    required String password,
  }) async {
    final ok = await ref
        .read(authProvider.notifier)
        .signInWithTestCredentials(id: id, password: password);
    if (!context.mounted) return;
    if (!ok) {
      showAppSnackBar(
        context,
        message: '아이디 또는 비밀번호가 올바르지 않습니다',
        isError: true,
      );
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
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
