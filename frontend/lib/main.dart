import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'app.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // (선택) 화면 방향 고정이 필요하면 유지: UI가 폰 회전에 깨지지 않게
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);

    // (선택) 상태바 아이콘 스타일
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));

    // .env 로드 (파일 없으면 optional)
    await dotenv.load(fileName: '.env', isOptional: true);

    final kakaoKey =
        (dotenv.isInitialized ? dotenv.env['KAKAO_JS_APP_KEY'] : null)
                ?.trim() ??
            '';

    final masked = (kakaoKey.length >= 4)
        ? '${kakaoKey.substring(0, 4)}••••'
        : (kakaoKey.isEmpty ? 'EMPTY' : 'SET');

    // ignore: avoid_print
    print(
      '[KAKAO] dotenv=${dotenv.isInitialized ? 'ok' : 'not_loaded'} key=$masked',
    );

    // ✅ Kakao Map plugin init (필수)
    if (kakaoKey.isNotEmpty) {
      // ignore: avoid_print
      print('[KAKAO] init start');
      AuthRepository.initialize(appKey: kakaoKey);
      // ignore: avoid_print
      print('[KAKAO] init done');
    } else {
      // ignore: avoid_print
      print(
        '[KAKAO] WARN: KAKAO_JS_APP_KEY is empty. ZoneEditor showMap=false.',
      );
    }

    _probeNetworkIfDebug();

    runApp(const ProviderScope(child: GyeongdoPlusApp()));
  }, (error, stack) {
    // ✅ iOS WebView/Pigeon 계열 플러그인에서 간헐적으로 발생하는 channel-error 무시
    if (error is PlatformException &&
        error.code == 'channel-error' &&
        (error.message ?? '')
            .contains('PigeonInternalInstanceManager.removeStrongReference')) {
      // ignore: avoid_print
      print('[WebView] ignored: ${error.code} ${error.message}');
      return;
    }

    // ignore: avoid_print
    print('[Uncaught] $error\n$stack');
  });
}

void _probeNetworkIfDebug() {
  const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
  if (isFlutterTest) return;

  // Keep this lightweight: prove ATS/network is not blocking basic HTTPS.
  scheduleMicrotask(() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);

      final req = await client.getUrl(Uri.parse('https://dapi.kakao.com/'));
      req.headers.add('User-Agent', 'GyeongdoPlus/ios-sim');

      final res = await req.close();
      // ignore: avoid_print
      print('[NET] https://dapi.kakao.com/ -> ${res.statusCode}');

      await res.drain<void>();
      client.close(force: true);
    } catch (e) {
      // ignore: avoid_print
      print('[NET] https://dapi.kakao.com/ failed: $e');
      // ignore: avoid_print
      print('[NET] Hint: ATS/Network/Domain allowlist may block WebView tiles.');
    }
  });
}
