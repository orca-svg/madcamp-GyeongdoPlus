import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomInfo {
  final String roomId;
  final String code;
  final String hostName;

  const RoomInfo({
    required this.roomId,
    required this.code,
    required this.hostName,
  });
}

class RoomResult<T> {
  final T? data;
  final String? errorMessage;

  const RoomResult._({this.data, this.errorMessage});

  bool get ok => data != null;

  factory RoomResult.ok(T data) => RoomResult._(data: data);
  factory RoomResult.fail(String message) =>
      RoomResult._(errorMessage: message);
}

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

class RoomRepository {
  final Random _rand = Random();

  Future<RoomResult<RoomInfo>> createRoom({required String myName}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final code = _newRoomCode();
    final info = RoomInfo(
      roomId: _newRoomId(),
      code: code,
      hostName: myName.isEmpty ? '김선수' : myName,
    );
    return RoomResult.ok(info);
  }

  Future<RoomResult<RoomInfo>> joinRoom({
    required String myName,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (code.toUpperCase() == 'AAAA') {
      return RoomResult.fail('유효하지 않은 방 코드입니다');
    }
    final info = RoomInfo(
      roomId: 'room_${code.toUpperCase()}',
      code: code.toUpperCase(),
      hostName: '방장',
    );
    return RoomResult.ok(info);
  }

  String _newRoomId() =>
      'room_${DateTime.now().microsecondsSinceEpoch}_${_rand.nextInt(1 << 16)}';

  String _newRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final len = 4 + _rand.nextInt(3);
    return List.generate(len, (_) => chars[_rand.nextInt(chars.length)]).join();
  }
}
