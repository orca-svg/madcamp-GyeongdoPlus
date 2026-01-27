import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/auth_api.dart';
import '../data/api/user_api.dart';
import '../data/api/lobby_api.dart';
import '../data/api/game_api.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/lobby_repository.dart';
import '../data/repositories/game_repository.dart';
import '../data/api_client.dart' as api_client;
import '../data/ws_client.dart';

// WebSocket Client
final wsClientProvider = Provider<WsClient>((ref) {
  final client = WsClient();
  ref.onDispose(client.dispose);
  return client;
});

// ============================================================================
// Retrofit API Providers
// ============================================================================

final authApiProvider = Provider<AuthApi>((ref) {
  final apiClient = ref.watch(api_client.apiClientProvider);
  return AuthApi(apiClient.dio);
});

final userApiProvider = Provider<UserApi>((ref) {
  final apiClient = ref.watch(api_client.apiClientProvider);
  return UserApi(apiClient.dio);
});

final lobbyApiProvider = Provider<LobbyApi>((ref) {
  final apiClient = ref.watch(api_client.apiClientProvider);
  return LobbyApi(apiClient.dio);
});

final gameApiProvider = Provider<GameApi>((ref) {
  final apiClient = ref.watch(api_client.apiClientProvider);
  return GameApi(apiClient.dio);
});

// ============================================================================
// Repository Providers
// ============================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authApi = ref.watch(authApiProvider);
  return AuthRepository(authApi);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final userApi = ref.watch(userApiProvider);
  return UserRepository(userApi);
});

final lobbyRepositoryProvider = Provider<LobbyRepository>((ref) {
  final lobbyApi = ref.watch(lobbyApiProvider);
  return LobbyRepository(lobbyApi);
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  final gameApi = ref.watch(gameApiProvider);
  return GameRepository(gameApi);
});
