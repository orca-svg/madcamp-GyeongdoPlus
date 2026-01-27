import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/env.dart';
import '../providers/auth_provider.dart';

/// Provider for ApiClient with automatic token injection from AuthProvider
final apiClientProvider = Provider<ApiClient>((ref) {
  final apiClient = ApiClient.create();

  // Listen to auth state changes and auto-update token
  ref.listen<AuthState>(authProvider, (previous, next) {
    final token = next.accessToken;
    apiClient.setAuthToken(token);
    debugPrint(
      '[ApiClient] Auth token updated: ${token != null ? 'SET' : 'CLEARED'}',
    );
  });

  // Initialize with current token if already signed in
  final currentAuth = ref.read(authProvider);
  if (currentAuth.accessToken != null) {
    apiClient.setAuthToken(currentAuth.accessToken);
  }

  return apiClient;
});

class ApiClient {
  final Dio dio;
  String? _cachedToken;

  ApiClient._(this.dio);

  factory ApiClient.create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final client = ApiClient._(dio);

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
        onError: (error, handler) {
          final statusCode = error.response?.statusCode;
          debugPrint(
            '[ApiClient] Error: $statusCode ${error.requestOptions.path}',
          );

          // Handle 401 Unauthorized
          if (statusCode == 401) {
            debugPrint('[ApiClient] 401 Unauthorized - Token may be expired');
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
