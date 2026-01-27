import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(apiClientProvider));
});

class HistoryRepository {
  final ApiClient _apiClient;

  HistoryRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> fetchHistory() async {
    try {
      final response = await _apiClient.dio.get('/user/me/history');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['history'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (_) {
      // API error fallback (empty history)
      return [];
    } catch (_) {
      return [];
    }
  }
}
