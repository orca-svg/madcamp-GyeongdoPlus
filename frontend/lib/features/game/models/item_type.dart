import '../../../providers/room_provider.dart';

/// Asset path helper for item images
class ItemAssets {
  static const String basePath = 'assets/items/';

  static String getPath(ItemType type) => switch (type) {
        ItemType.radar => '${basePath}radar.png',
        ItemType.block => '${basePath}stopper.png',
        ItemType.detector => '${basePath}thiefChecker.png',
        ItemType.siren => '${basePath}siren.png',
        ItemType.decoy => '${basePath}trap.png',
        ItemType.boost => '${basePath}faster.png',
        ItemType.emp => '${basePath}EMP.jpg',
        ItemType.remoteRescue => '${basePath}rescue.jpg',
        ItemType.none => '',
      };
}

/// Item type enum with metadata
enum ItemType {
  // Police Items
  radar(
    id: 'RADAR',
    label: '레이더',
    team: Team.police,
    description: '7초간 적군 위치 노출',
    cooldownSec: 60,
    durationSec: 7,
  ),
  block(
    id: 'BLOCK',
    label: '차단기',
    team: Team.police,
    description: '구출 차단',
    cooldownSec: 45,
    durationSec: 0,
  ),
  detector(
    id: 'DETECTOR',
    label: '탐지기',
    team: Team.police,
    description: '5m 이내 적 탐지 시 진동',
    cooldownSec: 30,
    durationSec: 15,
  ),
  siren(
    id: 'SIREN',
    label: '사이렌',
    team: Team.police,
    description: '30m 내 도둑에게 소음 경보',
    cooldownSec: 90,
    durationSec: 0,
  ),

  // Thief Items
  decoy(
    id: 'DECOY',
    label: '미끼',
    team: Team.thief,
    description: '가짜 마커 생성',
    cooldownSec: 60,
    durationSec: 20,
  ),
  boost(
    id: 'BOOST',
    label: '부스터',
    team: Team.thief,
    description: '구출 속도 촉진',
    cooldownSec: 45,
    durationSec: 10,
  ),
  emp(
    id: 'EMP',
    label: 'EMP',
    team: Team.thief,
    description: '15초간 경찰 아이템 무효화',
    cooldownSec: 120,
    durationSec: 15,
  ),
  remoteRescue(
    id: 'REMOTE_RESCUE',
    label: '원격 구출',
    team: Team.thief,
    description: '원격으로 동료 구출',
    cooldownSec: 180,
    durationSec: 0,
  ),

  // Empty slot
  none(
    id: 'NONE',
    label: '',
    team: null,
    description: '',
    cooldownSec: 0,
    durationSec: 0,
  );

  final String id;
  final String label;
  final Team? team;
  final String description;
  final int cooldownSec;
  final int durationSec;

  const ItemType({
    required this.id,
    required this.label,
    required this.team,
    required this.description,
    required this.cooldownSec,
    required this.durationSec,
  });

  /// Get asset path
  String get assetPath => ItemAssets.getPath(this);

  /// Check if instant effect (no duration)
  bool get isInstant => durationSec == 0;

  /// Parse from wire format string
  static ItemType fromWire(String wire) {
    return ItemType.values.firstWhere(
      (t) => t.id == wire,
      orElse: () => ItemType.none,
    );
  }

  /// Get all items for a team
  static List<ItemType> forTeam(Team team) {
    return ItemType.values.where((t) => t.team == team).toList();
  }
}
