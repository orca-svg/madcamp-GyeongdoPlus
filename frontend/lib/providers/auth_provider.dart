import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { signedOut, signingIn, signedIn }

class AuthState {
  final bool initialized;
  final AuthStatus status;
  final String? accessToken;
  final String? displayName;

  const AuthState({
    required this.initialized,
    required this.status,
    required this.accessToken,
    required this.displayName,
  });

  AuthState copyWith({
    bool? initialized,
    AuthStatus? status,
    String? accessToken,
    String? displayName,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      status: status ?? this.status,
      accessToken: accessToken ?? this.accessToken,
      displayName: displayName ?? this.displayName,
    );
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  static const _kAccessToken = 'auth_access_token';
  static const _kDisplayName = 'auth_display_name';

  bool _loadStarted = false;

  @override
  AuthState build() {
    if (!_loadStarted) {
      _loadStarted = true;
      unawaited(_loadFromPrefs());
    }

    return const AuthState(
      initialized: false,
      status: AuthStatus.signedOut,
      accessToken: null,
      displayName: null,
    );
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccessToken);
    final name = prefs.getString(_kDisplayName);

    if (token != null && token.isNotEmpty) {
      state = state.copyWith(
        initialized: true,
        status: AuthStatus.signedIn,
        accessToken: token,
        displayName: (name == null || name.isEmpty) ? '익명' : name,
      );
      return;
    }

    state = state.copyWith(
      initialized: true,
      status: AuthStatus.signedOut,
      accessToken: null,
      displayName: null,
    );
  }

  Future<void> signInWithKakaoStub() async {
    if (state.status == AuthStatus.signingIn) return;
    state = state.copyWith(status: AuthStatus.signingIn);

    // TODO(next): real Kakao OAuth + exchange to JWT
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final token = 'stub_token_${DateTime.now().millisecondsSinceEpoch}';
    const name = '익명';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, token);
    await prefs.setString(_kDisplayName, name);

    state = state.copyWith(
      initialized: true,
      status: AuthStatus.signedIn,
      accessToken: token,
      displayName: name,
    );
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kDisplayName);
    state = state.copyWith(
      initialized: true,
      status: AuthStatus.signedOut,
      accessToken: null,
      displayName: null,
    );
  }
}

