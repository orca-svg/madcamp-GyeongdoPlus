import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  /// API Base URL - reads from dotenv first, then compile-time env var
  static String get apiBaseUrl {
    if (dotenv.isInitialized) {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    }
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    );
  }

  /// Socket.IO URL - reads from dotenv first, then compile-time env var
  static String get socketIoUrl {
    if (dotenv.isInitialized) {
      final envUrl = dotenv.env['SOCKET_IO_URL'];
      if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    }
    return const String.fromEnvironment(
      'SOCKET_IO_URL',
      defaultValue: 'http://localhost:3000',
    );
  }

  /// Legacy WebSocket URL (deprecated, use socketIoUrl)
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:3000',
  );
}
