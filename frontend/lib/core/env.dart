class Env {
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');

  static const String wsUrl =
      String.fromEnvironment('WS_URL', defaultValue: 'ws://localhost:3000');
}
