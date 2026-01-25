import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env', isOptional: true);
  final kakaoKey = (dotenv.isInitialized ? dotenv.env['KAKAO_JS_APP_KEY'] : null)?.trim() ?? '';

  if (kakaoKey.isNotEmpty) {
    AuthRepository.initialize(appKey: kakaoKey);
  }

  runApp(const ProviderScope(child: GyeongdoPlusApp()));
}
