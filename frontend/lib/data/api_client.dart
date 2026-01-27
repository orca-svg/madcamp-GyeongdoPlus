import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/env.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.create();
});

class ApiClient {
  final Dio dio;

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

    // Add JWT interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // JWT token will be added by individual API calls
          // or can be injected via ref.read(authProvider).accessToken
          handler.next(options);
        },
        onError: (error, handler) {
          // Global error handling
          handler.next(error);
        },
      ),
    );

    return ApiClient._(dio);
  }

  /// Set JWT token for authenticated requests
  void setAuthToken(String? token) {
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      dio.options.headers.remove('Authorization');
    }
  }
}
