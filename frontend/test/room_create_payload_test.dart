import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/room/room_create_payload.dart';
import 'package:frontend/providers/match_rules_provider.dart';

void main() {
  test('buildRoomCreatePayload does not inject sample zone when unset', () {
    final payload = buildRoomCreatePayload(RoomCreateFormState.initial());
    final mapConfig = payload['mapConfig'] as Map<String, dynamic>;

    expect(mapConfig['polygon'], isEmpty);
    expect(mapConfig.containsKey('jail'), isFalse);
  });

  test('buildCircularZonePolygon builds a current-location default arena', () {
    const center = GeoPointDto(lat: 37.5665, lng: 126.9780);

    final polygon = buildCircularZonePolygon(center: center, radiusM: 10);

    expect(polygon, hasLength(16));
    expect(
      polygon.every((p) => p.lat != center.lat || p.lng != center.lng),
      isTrue,
    );
  });
}
