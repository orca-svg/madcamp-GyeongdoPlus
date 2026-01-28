import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import '../../core/app_dimens.dart';
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

class _LoginScreenState extends ConsumerState<LoginScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[UI] AppLifecycleState: $state');
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
                        onPressed: () => _handleKakaoLogin(context),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '카카오 SDK 연동 후 로그인이 활성화됩니다.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Network Status Indicator for Debugging
                      FutureBuilder<bool>(
                        future: _checkNetwork(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final isOnline = snapshot.data!;
                          return Text(
                            isOnline
                                ? 'Network: Online'
                                : 'Network: OFFLINE (Check Wi-Fi)',
                            style: TextStyle(
                              color: isOnline ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
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
                      SizedBox(height: AppDimens.padding16),
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

  Future<void> _handleKakaoLogin(BuildContext context) async {
    print('[UI] _handleKakaoLogin start');
    // 1. Check if KakaoTalk installed
    bool isInstalled = false;
    // try {
    //   isInstalled = await isKakaoTalkInstalled();
    //   print('[UI] isKakaoTalkInstalled: $isInstalled');
    // } catch (e) {
    //   print('[UI] isKakaoTalkInstalled checking failed: $e');
    // }

    OAuthToken? token;

    try {
      // Force Web Login for debugging (Bypass App Switch)
      if (false /* isInstalled */ ) {
        print('[UI] Try loginWithKakaoTalk');
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
          print(
            '[UI] loginWithKakaoTalk success, token=${token.accessToken.substring(0, 5)}...',
          );
        } catch (e) {
          print('[UI] loginWithKakaoTalk failed: $e');
          // Fallback
          if (e is KakaoAuthException &&
              (e.message?.contains('cancelled') ?? false)) {
            print('[UI] User cancelled login');
            return;
          }
          print('[UI] Fallback to loginWithKakaoAccount');
          token = await UserApi.instance.loginWithKakaoAccount();
          print('[UI] loginWithKakaoAccount success');
        }
      } else {
        print('[UI] Try loginWithKakaoAccount (Talk not installed)');
        token = await UserApi.instance.loginWithKakaoAccount();
        print('[UI] loginWithKakaoAccount success');
      }
    } catch (e) {
      print('[UI] Kakao Login Error: $e');
      if (!context.mounted) return;
      showAppSnackBar(context, message: '카카오 로그인 실패: $e', isError: true);
      return;
    }

    if (token == null) {
      print('[UI] Token is null');
      return;
    }

    print('[UI] Calling authProvider.signInWithKakao...');
    if (!context.mounted) return;
    await ref.read(authProvider.notifier).signInWithKakao(token.accessToken);
    print('[UI] authProvider.signInWithKakao done');
  }

  // ignore: unused_element
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

  Future<bool> _checkNetwork() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      final req = await client.getUrl(Uri.parse('https://www.google.com'));
      final res = await req.close();
      await res.drain();
      return res.statusCode == 200;
    } catch (e) {
      print('[UI] Network Check Failed: $e');
      return false;
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
