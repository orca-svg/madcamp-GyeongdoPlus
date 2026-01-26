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

    await dotenv.load(fileName: '.env', isOptional: true);
    final kakaoKey = (dotenv.isInitialized ? dotenv.env['KAKAO_JS_APP_KEY'] : null)?.trim() ?? '';

    final masked = (kakaoKey.length >= 4) ? '${kakaoKey.substring(0, 4)}••••' : (kakaoKey.isEmpty ? 'EMPTY' : 'SET');
    // ignore: avoid_print
    print('[KAKAO] dotenv=${dotenv.isInitialized ? 'ok' : 'not_loaded'} key=$masked');

    if (kakaoKey.isNotEmpty) {
      AuthRepository.initialize(appKey: kakaoKey);
    }

    _probeNetworkIfDebug();

    runApp(const ProviderScope(child: GyeongdoPlusApp()));
  }, (error, stack) {
    if (error is PlatformException &&
        error.code == 'channel-error' &&
        (error.message ?? '').contains('PigeonInternalInstanceManager.removeStrongReference')) {
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
    }
  });
}
