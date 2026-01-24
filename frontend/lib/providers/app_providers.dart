import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_client.dart';
import '../data/ws_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.create();
});

final wsClientProvider = Provider<WsClient>((ref) {
  final client = WsClient();
  ref.onDispose(client.dispose);
  return client;
});
