import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/env.dart';
import '../providers/auth_provider.dart';

/// Provider for ApiClient with automatic token injection from AuthProvider
/// Provider for ApiClient
/// Circular dependency fixed: AuthProvider will push token updates to this client.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.create(
    onRefreshToken: () async {
      // Lazy read to avoid cyclic init
      final authController = ref.read(authProvider.notifier);
      return await authController.refreshAccessToken();
    },
    onSignOut: () {
      // Lazy read
      final authController = ref.read(authProvider.notifier);
      authController.signOut();
    },
  );
});

class ApiClient {
  final Dio dio;
  String? _cachedToken;
  final Future<String?> Function()? _onRefreshToken;
  final void Function()? _onSignOut;
  bool _isRefreshing = false;

  ApiClient._(this.dio, this._onRefreshToken, this._onSignOut);

  factory ApiClient.create({
    Future<String?> Function()? onRefreshToken,
    void Function()? onSignOut,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final client = ApiClient._(dio, onRefreshToken, onSignOut);

    // Add JWT interceptor that reads cached token on each request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Always use latest cached token
          final token = client._cachedToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('[ApiClient] Request: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '[ApiClient] Response: ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          debugPrint(
            '[ApiClient] Error: $statusCode ${error.requestOptions.path}',
          );

          // Handle 401 Unauthorized - RTR (Rotate Token Request)
          if (statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/refresh') &&
              !client._isRefreshing) {
            debugPrint(
              '[ApiClient] 401 Unauthorized - Attempting token refresh',
            );
            client._isRefreshing = true;

            try {
              // Call refresh callback
              final newToken = await client._onRefreshToken?.call();

              if (newToken != null && newToken.isNotEmpty) {
                // Update token
                client.setAuthToken(newToken);

                // Retry original request with new token
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newToken';

                debugPrint('[ApiClient] Token refreshed, retrying request');
                final response = await dio.fetch(options);
                return handler.resolve(response);
              } else {
                // Refresh failed - sign out
                debugPrint('[ApiClient] Token refresh failed - signing out');
                client._onSignOut?.call();
              }
            } catch (e) {
              debugPrint('[ApiClient] Token refresh error: $e');
              client._onSignOut?.call();
            } finally {
              client._isRefreshing = false;
            }
          }

          handler.next(error);
        },
      ),
    );

    return client;
  }

  /// Set JWT token for authenticated requests
  void setAuthToken(String? token) {
    _cachedToken = token;
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      dio.options.headers.remove('Authorization');
    }
  }

  /// Clear auth token (for logout)
  void clearAuthToken() {
    _cachedToken = null;
    dio.options.headers.remove('Authorization');
    debugPrint('[ApiClient] Auth token cleared');
  }

  /// Get current cached token
  String? get currentToken => _cachedToken;
}
