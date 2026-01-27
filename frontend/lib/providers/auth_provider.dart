import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/auth_api.dart';
import '../data/dto/auth_dto.dart';
import '../data/models/user_model.dart';

enum AuthStatus { signedOut, signingIn, signedIn }

class AuthState {
  final bool initialized;
  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final String? displayName;
  final UserModel? user;

  const AuthState({
    required this.initialized,
    required this.status,
    required this.accessToken,
    this.refreshToken,
    required this.displayName,
    this.user,
  });

  AuthState copyWith({
    bool? initialized,
    AuthStatus? status,
    String? accessToken,
    String? refreshToken,
    String? displayName,
    UserModel? user,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      status: status ?? this.status,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      displayName: displayName ?? this.displayName,
      user: user ?? this.user,
    );
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kDisplayName = 'auth_display_name';
  static const _allowInmemAuth = bool.fromEnvironment(
    'ALLOW_INMEM_AUTH',
    defaultValue: false,
  );

  bool _loadStarted = false;

  Future<SharedPreferences?> _tryPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  @override
  AuthState build() {
    const initial = AuthState(
      initialized: false,
      status: AuthStatus.signedOut,
      accessToken: null,
      displayName: null,
    );
    if (!_loadStarted) {
      _loadStarted = true;
      Future.microtask(_loadFromPrefs);
    }
    return initial;
  }

  Future<void> _loadFromPrefs() async {
    debugPrint('[AUTH] loadFromPrefs start');
    try {
      if (state.status == AuthStatus.signedIn) {
        debugPrint('[AUTH] loadFromPrefs result=skip(already signedIn)');
        return;
      }
      final prefs = await _tryPrefs();
      if (prefs == null) {
        debugPrint(
          '[AUTH] prefs unavailable (fallback=${_allowInmemAuth ? 'enabled' : 'disabled'})',
        );
        state = state.copyWith(
          initialized: true,
          status: AuthStatus.signedOut,
          accessToken: null,
          displayName: null,
        );
        return;
      }
      final token = prefs.getString(_kAccessToken);
      final refreshToken = prefs.getString(_kRefreshToken);
      final name = prefs.getString(_kDisplayName);

      if (token != null && token.isNotEmpty) {
        state = state.copyWith(
          initialized: true,
          status: AuthStatus.signedIn,
          accessToken: token,
          refreshToken: refreshToken,
          displayName: (name == null || name.isEmpty) ? '익명' : name,
        );
        debugPrint('[AUTH] loadFromPrefs result=signedIn');
        return;
      }

      state = state.copyWith(
        initialized: true,
        status: AuthStatus.signedOut,
        accessToken: null,
        displayName: null,
      );
      debugPrint('[AUTH] loadFromPrefs result=signedOut');
    } catch (e, st) {
      debugPrint('[AUTH] loadFromPrefs error=$e\n$st');
      state = state.copyWith(
        initialized: true,
        status: AuthStatus.signedOut,
        accessToken: null,
        displayName: null,
      );
    }
  }

  Future<bool> signInWithTestCredentials({
    required String id,
    required String password,
  }) async {
    if (state.status == AuthStatus.signingIn) return false;
    state = state.copyWith(status: AuthStatus.signingIn);
    debugPrint('[AUTH] signIn(test) start');

    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      // Mock validation
      if (id.isNotEmpty) {
        final token = 'test_token_${DateTime.now().millisecondsSinceEpoch}';
        final user = UserModel.guest().copyWith(nickname: id);

        state = state.copyWith(
          initialized: true,
          status: AuthStatus.signedIn,
          accessToken: token,
          displayName: id,
          user: user,
        );

        final prefs = await _tryPrefs();
        if (prefs != null) {
          await prefs.setString(_kAccessToken, token);
          await prefs.setString(_kDisplayName, id);
        }
        return true;
      }
      return false;
    } catch (_) {
      state = state.copyWith(status: AuthStatus.signedOut);
      return false;
    }
  }

  Future<void> signInWithKakao(String kakaoAccessToken) async {
    if (state.status == AuthStatus.signingIn) return;
    state = state.copyWith(status: AuthStatus.signingIn);
    debugPrint('[AUTH] signIn(kakao) start');

    try {
      final api = ref.read(authApiProvider);
      final request = KakaoLoginRequest(kakaoAccessToken: kakaoAccessToken);
      final response = await api.loginWithKakao(request);

      if (response.success && response.data != null) {
        final data = response.data!;
        state = state.copyWith(
          initialized: true,
          status: AuthStatus.signedIn,
          accessToken: data.accessToken,
          displayName: data.user?.nickname ?? '익명',
          user: data.user,
        );

        final prefs = await _tryPrefs();
        if (prefs != null) {
          await prefs.setString(_kAccessToken, data.accessToken);
          await prefs.setString(_kDisplayName, data.user?.nickname ?? '익명');
        }
        debugPrint('[AUTH] signIn(kakao) success');
      } else {
        debugPrint('[AUTH] signIn(kakao) failed: ${response.error}');
        state = state.copyWith(
          initialized: true,
          status: AuthStatus.signedOut,
          accessToken: null,
          displayName: null,
        );
      }
    } catch (e, st) {
      debugPrint('[AUTH] signIn(kakao) error=$e\n$st');
      state = state.copyWith(
        initialized: true,
        status: AuthStatus.signedOut,
        accessToken: null,
        displayName: null,
      );
    } finally {
      if (state.status == AuthStatus.signingIn) {
        state = state.copyWith(
          initialized: true,
          status: AuthStatus.signedOut,
          accessToken: null,
          displayName: null,
        );
      }
    }
  }

  /// 카카오 로그인 (실제 API 호출)
  Future<void> signInWithKakaoStub() async {
    if (state.status == AuthStatus.signingIn) return;
    state = state.copyWith(status: AuthStatus.signingIn);
    debugPrint('[AUTH] signIn(kakao-stub) start');

    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final token = 'stub_token_${DateTime.now().millisecondsSinceEpoch}';
      const name = '익명(Stub)';
      final guestUser = UserModel.guest().copyWith(nickname: name);

      state = state.copyWith(
        initialized: true,
        status: AuthStatus.signedIn,
        accessToken: token,
        displayName: name,
        user: guestUser,
      );

      final prefs = await _tryPrefs();
      if (prefs != null) {
        await prefs.setString(_kAccessToken, token);
        await prefs.setString(_kDisplayName, name);
      }
    } catch (_) {
      // ignore
    } finally {
      if (state.status == AuthStatus.signingIn) {
        state = state.copyWith(status: AuthStatus.signedOut);
      }
    }
  }

  /// 토큰 갱신 (ApiClient RTR에서 호출)
  Future<String?> refreshAccessToken() async {
    debugPrint('[AUTH] refreshAccessToken start');

    try {
      final currentRefreshToken = state.refreshToken;
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        debugPrint('[AUTH] refreshAccessToken failed: no refresh token');
        return null;
      }

      final authApi = ref.read(authApiProvider);
      final request = RefreshRequest(refreshToken: currentRefreshToken);
      final response = await authApi.refreshToken(request);

      if (!response.success || response.data == null) {
        debugPrint('[AUTH] refreshAccessToken failed: ${response.error}');
        return null;
      }

      final data = response.data!;

      // Update state with new tokens
      state = state.copyWith(
        accessToken: data.accessToken,
        refreshToken: data.refreshToken,
      );

      // Save new tokens to SharedPreferences
      final prefs = await _tryPrefs();
      if (prefs != null) {
        await prefs.setString(_kAccessToken, data.accessToken);
        await prefs.setString(_kRefreshToken, data.refreshToken);
      }

      debugPrint('[AUTH] refreshAccessToken success');
      return data.accessToken;
    } catch (e, st) {
      debugPrint('[AUTH] refreshAccessToken error=$e\n$st');
      return null;
    }
  }

  Future<void> signOut() async {
    // Call logout API
    try {
      final authApi = ref.read(authApiProvider);
      await authApi.logout();
    } catch (e) {
      debugPrint('[AUTH] logout API error: $e');
    }

    // Clear local storage
    final prefs = await _tryPrefs();
    if (prefs != null) {
      await prefs.remove(_kAccessToken);
      await prefs.remove(_kRefreshToken);
      await prefs.remove(_kDisplayName);
    } else {
      debugPrint(
        '[AUTH] prefs unavailable (fallback=${_allowInmemAuth ? 'enabled' : 'disabled'})',
      );
    }
    state = state.copyWith(
      initialized: true,
      status: AuthStatus.signedOut,
      accessToken: null,
      refreshToken: null,
      displayName: null,
      user: null,
    );
    debugPrint('[AUTH] signOut');
  }
}
