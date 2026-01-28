import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'app.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      final stopWatch = Stopwatch()..start();

      WidgetsFlutterBinding.ensureInitialized();
      print('[perf] WidgetsFlutterBinding: ${stopWatch.elapsedMilliseconds}ms');

      // (선택) 화면 방향 고정이 필요하면 유지: UI가 폰 회전에 깨지지 않게
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
      print(
        '[perf] setPreferredOrientations: ${stopWatch.elapsedMilliseconds}ms',
      );

      // (선택) 상태바 아이콘 스타일
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
      );

      // .env 로드 (파일 없으면 optional)
      await dotenv.load(fileName: '.env', isOptional: true);
      print('[perf] dotenv.load: ${stopWatch.elapsedMilliseconds}ms');

      final kakaoJsKey =
          (dotenv.isInitialized ? dotenv.env['KAKAO_JS_APP_KEY'] : null)
              ?.trim() ??
          '';
      final kakaoNativeKey =
          (dotenv.isInitialized ? dotenv.env['KAKAO_NATIVE_APP_KEY'] : null)
              ?.trim() ??
          '';

      // ignore: avoid_print
      print(
        '[KAKAO] JS_KEY=${kakaoJsKey.isNotEmpty ? "OK" : "EMPTY"} NATIVE_KEY=${kakaoNativeKey.isNotEmpty ? "OK" : "EMPTY"}',
      );

      // ✅ Kakao Map plugin init
      if (kakaoJsKey.isNotEmpty) {
        AuthRepository.initialize(
          appKey: kakaoJsKey,
          baseUrl: 'http://localhost',
        );
      }

      // ✅ Kakao Login SDK init
      if (kakaoNativeKey.isNotEmpty || kakaoJsKey.isNotEmpty) {
        KakaoSdk.init(
          nativeAppKey: kakaoNativeKey,
          javaScriptAppKey: kakaoJsKey,
        );
        // ignore: avoid_print
        print('[KAKAO] SDK Initialized');
      } else {
        // ignore: avoid_print
        print('[KAKAO] WARN: No keys found. Login/Map may fail.');
      }
      print('[perf] Kakao init: ${stopWatch.elapsedMilliseconds}ms');

      _probeNetworkIfDebug();

      print('[perf] runApp start: ${stopWatch.elapsedMilliseconds}ms');
      runApp(const ProviderScope(child: GyeongdoPlusApp()));
    },
    (error, stack) {
      // ✅ iOS WebView/Pigeon 계열 플러그인에서 간헐적으로 발생하는 channel-error 무시
      if (error is PlatformException &&
          error.code == 'channel-error' &&
          (error.message ?? '').contains(
            'PigeonInternalInstanceManager.removeStrongReference',
          )) {
        // ignore: avoid_print
        print('[WebView] ignored: ${error.code} ${error.message}');
        return;
      }

      // ignore: avoid_print
      print('[Uncaught] $error\n$stack');
    },
  );
}

void _probeNetworkIfDebug() {
  const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
  if (isFlutterTest) return;

  // Keep this lightweight: prove ATS/network is not blocking basic HTTPS.
  scheduleMicrotask(() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2); // Reduced from 6s

      final req = await client.getUrl(Uri.parse('https://map.kakao.com'));
      // req.headers.add('User-Agent', ...);

      final res = await req.close();
      // ignore: avoid_print
      print('[NET] https://map.kakao.com -> ${res.statusCode}');

      await res.drain<void>();
      client.close(force: true);
    } catch (e) {
      // ignore: avoid_print
      print('[NET] https://dapi.kakao.com/ failed: $e');
      // ignore: avoid_print
      print(
        '[NET] Hint: ATS/Network/Domain allowlist may block WebView tiles.',
      );
    }
  });
}
