import '../../data/api/game_api.dart';
import '../../data/dto/game_dto.dart';
import '../../net/socket/socket_io_client_provider.dart';
import 'repository_result.dart';

abstract class LobbyEvent {}

class MemberJoinedEvent extends LobbyEvent {
  final Map<String, dynamic> payload;
  MemberJoinedEvent(this.payload);
}

class MemberLeftEvent extends LobbyEvent {
  final String userId;
  final Map<String, dynamic> payload;
  MemberLeftEvent(this.userId, this.payload);
}

class MemberUpdatedEvent extends LobbyEvent {
  final Map<String, dynamic> payload;
  MemberUpdatedEvent(this.payload);
}

class RoomUpdatedEvent extends LobbyEvent {
  final Map<String, dynamic> payload;
  RoomUpdatedEvent(this.payload);
}

class HostChangedEvent extends LobbyEvent {
  final String hostId;
  HostChangedEvent(this.hostId);
}

class GameStartedEvent extends LobbyEvent {}

class JoinedRoomEvent extends LobbyEvent {
  final Map<String, dynamic> payload;
  JoinedRoomEvent(this.payload);
}

class GameRepository {
  final GameApi _api;
  final SocketIoController _socket;

  GameRepository(this._api, this._socket);

  /// Map raw socket events to domain-specific LobbyEvents
  Stream<LobbyEvent> listenToRoomEvents() {
    return _socket.events
        .map((event) {
          final payload = event.payload;

          switch (event.name) {
            case 'game_started':
              return GameStartedEvent();

            case 'joined_room':
              if (payload is Map<String, dynamic>) {
                return JoinedRoomEvent(payload);
              }
              return null;

            case 'user_joined':
            case 'player_joined':
            case 'member_joined':
              if (payload is Map<String, dynamic>) {
                return MemberJoinedEvent(payload);
              } else if (payload is List &&
                  payload.isNotEmpty &&
                  payload[0] is Map) {
                // If it's a list, we might want to sync full members
                return RoomUpdatedEvent({'members': payload});
              }
              return null;

            case 'user_left':
            case 'player_left':
            case 'member_left':
              if (payload is Map<String, dynamic>) {
                final userId =
                    payload['leftUserId'] ??
                    payload['userId'] ??
                    payload['id'] ??
                    payload['user_id'];
                return MemberLeftEvent(userId?.toString() ?? '', payload);
              } else if (payload is String) {
                return MemberLeftEvent(payload, {});
              }
              return null;

            case 'member_updated':
            case 'player_update':
            case 'player_updated':
            case 'team_changed':
            case 'role_changed':
            case 'change_team':
            case 'change_role':
            case 'ready_changed':
            case 'player_ready':
            case 'member_ready':
            case 'ready':
              if (payload is Map<String, dynamic>) {
                return MemberUpdatedEvent(payload);
              }
              return null;

            case 'room_updated':
            case 'settings_updated':
            case 'full_rules_update':
              if (payload is Map<String, dynamic>) {
                return RoomUpdatedEvent(payload);
              }
              return null;

            case 'host_changed':
            case 'new_host':
              if (payload is Map<String, dynamic>) {
                final hostId =
                    payload['hostId'] ??
                    payload['newHostId'] ??
                    payload['userId'] ??
                    payload['id'];
                return HostChangedEvent(hostId?.toString() ?? '');
              } else if (payload is String) {
                return HostChangedEvent(payload);
              }
              return null;

            default:
              return null;
          }
        })
        .where((e) => e != null)
        .cast<LobbyEvent>();
  }

  Future<RepositoryResult<MoveResponseDataDto>> move(MoveDto dto) async {
    try {
      final response = await _api.move(dto);
      if (response.success) {
        return RepositoryResult.success(response.data);
      } else {
        return RepositoryResult.failure(response.message);
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<ArrestDataDto>> arrest(
    String matchId,
    String targetId,
  ) async {
    try {
      final response = await _api.arrest(
        ArrestDto(matchId: matchId, targetId: targetId),
      );
      if (response.success) {
        return RepositoryResult.success(response.data);
      } else {
        return RepositoryResult.failure(response.message);
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<void>> selectItem(SelectItemDto dto) async {
    try {
      final response = await _api.selectItem(dto);
      if (response.success) {
        return RepositoryResult.success(null);
      } else {
        return RepositoryResult.failure(response.message);
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<void>> useItem(UseItemDto dto) async {
    try {
      final response = await _api.useItem(dto);
      if (response.success) {
        return RepositoryResult.success(null);
      } else {
        return RepositoryResult.failure(response.message);
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<void>> selectAbility(SelectAbilityDto dto) async {
    try {
      final response = await _api.selectAbility(dto);
      if (response.success) {
        return RepositoryResult.success(null);
      } else {
        return RepositoryResult.failure(response.message);
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }

  Future<RepositoryResult<UseAbilityResponseDto>> useAbility(
    UseAbilityDto dto,
  ) async {
    try {
      final response = await _api.useAbility(dto);
      if (response.success) {
        return RepositoryResult.success(response);
      } else {
        return RepositoryResult.failure(response.message);
      }
    } catch (e) {
      return RepositoryResult.failure(e.toString());
    }
  }
}
