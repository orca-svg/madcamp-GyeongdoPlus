import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user_model.dart';

enum AuthStatus { signedOut, signingIn, signedIn }

class AuthState {
  final bool initialized;
  final AuthStatus status;
  final String? accessToken;
  final String? displayName;
  final UserModel? user;

  const AuthState({
    required this.initialized,
    required this.status,
    required this.accessToken,
    required this.displayName,
    this.user,
  });

  AuthState copyWith({
    bool? initialized,
    AuthStatus? status,
    String? accessToken,
    String? displayName,
    UserModel? user,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      status: status ?? this.status,
      accessToken: accessToken ?? this.accessToken,
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
      final name = prefs.getString(_kDisplayName);

      if (token != null && token.isNotEmpty) {
        state = state.copyWith(
          initialized: true,
          status: AuthStatus.signedIn,
          accessToken: token,
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

  Future<void> signInWithKakaoStub() async {
    if (state.status == AuthStatus.signingIn) return;
    state = state.copyWith(status: AuthStatus.signingIn);
    debugPrint('[AUTH] signIn(kakao) start');

    try {
      // TODO(next): real Kakao OAuth + exchange to JWT
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final token = 'stub_token_${DateTime.now().millisecondsSinceEpoch}';
      const name = '익명';
      final guestUser = UserModel.guest().copyWith(nickname: name);

      state = state.copyWith(
        initialized: true,
        status: AuthStatus.signedIn,
        accessToken: token,
        displayName: name,
        user: guestUser,
      );
      final prefs = await _tryPrefs();
      if (prefs == null) {
        debugPrint(
          '[AUTH] prefs unavailable (fallback=${_allowInmemAuth ? 'enabled' : 'disabled'})',
        );
        if (!_allowInmemAuth) {
          state = state.copyWith(
            initialized: true,
            status: AuthStatus.signedOut,
            accessToken: null,
            displayName: null,
          );
        }
      } else {
        await prefs.setString(_kAccessToken, token);
        await prefs.setString(_kDisplayName, name);
      }
      debugPrint(
        '[AUTH] signIn(kakao) result=${state.status == AuthStatus.signedIn ? 'signedIn' : 'signedOut'}',
      );
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

  Future<bool> signInWithTestCredentials({
    required String id,
    required String password,
  }) async {
    if (state.status == AuthStatus.signingIn) return false;
    state = state.copyWith(status: AuthStatus.signingIn);
    debugPrint('[AUTH] signIn(test) start');

    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));

      if (id.trim() != 'test' || password != '12341234') {
        state = state.copyWith(
          initialized: true,
          status: AuthStatus.signedOut,
          accessToken: null,
          displayName: null,
        );
        debugPrint('[AUTH] signIn(test) result=invalid');
        return false;
      }

      final token = 'stub_local_${DateTime.now().millisecondsSinceEpoch}';
      const name = 'test';
      final testUser = UserModel.guest().copyWith(
        nickname: name,
        policeScore: 1240,
        thiefScore: 980,
        policeRank: 'BRONZE',
        thiefRank: 'SILVER',
        totalGames: 15,
        wins: 8,
        losses: 7,
        winRate: 0.533,
        mannerScore: 85,
        totalPlayTimeSec: 13400,
      );

      state = state.copyWith(
        initialized: true,
        status: AuthStatus.signedIn,
        accessToken: token,
        displayName: name,
        user: testUser,
      );
      final prefs = await _tryPrefs();
      if (prefs == null) {
        debugPrint(
          '[AUTH] prefs unavailable (fallback=${_allowInmemAuth ? 'enabled' : 'disabled'})',
        );
        if (!_allowInmemAuth) {
          state = state.copyWith(
            initialized: true,
            status: AuthStatus.signedOut,
            accessToken: null,
            displayName: null,
          );
        }
      } else {
        await prefs.setString(_kAccessToken, token);
        await prefs.setString(_kDisplayName, name);
      }
      debugPrint(
        '[AUTH] signIn(test) result=${state.status == AuthStatus.signedIn ? 'signedIn' : 'signedOut'}',
      );
      return state.status == AuthStatus.signedIn;
    } catch (e, st) {
      debugPrint('[AUTH] signIn(test) error=$e\n$st');
      state = state.copyWith(
        initialized: true,
        status: AuthStatus.signedOut,
        accessToken: null,
        displayName: null,
      );
      return false;
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

  Future<void> signOut() async {
    final prefs = await _tryPrefs();
    if (prefs != null) {
      await prefs.remove(_kAccessToken);
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
      displayName: null,
    );
    debugPrint('[AUTH] signOut');
  }
}
