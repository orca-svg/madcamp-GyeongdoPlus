class Env {
  static bool _forceDisableMaps = false;

  static String _trimmed(String value) => value.trim();

  static String get apiBaseUrl => _trimmed(
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://127.0.0.1:3000',
        ),
      );

  static String get socketIoUrl => _trimmed(
        const String.fromEnvironment(
          'SOCKET_IO_URL',
          defaultValue: 'http://127.0.0.1:3000',
        ),
      );

  static String get wsUrl => _trimmed(
        const String.fromEnvironment(
          'WS_URL',
          defaultValue: 'ws://127.0.0.1:3000/v1/ws',
        ),
      );

  static String get kakaoJsAppKey =>
      _trimmed(const String.fromEnvironment('KAKAO_JS_APP_KEY'));

  static String get kakaoNativeAppKey =>
      _trimmed(const String.fromEnvironment('KAKAO_NATIVE_APP_KEY'));

  static bool get allowInMemAuth =>
      const bool.fromEnvironment('ALLOW_INMEM_AUTH', defaultValue: false);

  static bool get canRenderMaps =>
      !_forceDisableMaps && kakaoJsAppKey.isNotEmpty;

  static void debugForceDisableMaps(bool value) {
    _forceDisableMaps = value;
  }
}
