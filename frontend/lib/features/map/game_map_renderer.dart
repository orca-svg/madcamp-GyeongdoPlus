import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/match_rules_provider.dart';

/// Helper class to generate KakaoMap overlays (Polygons/Circles)
/// from game configuration data.
class GameMapRenderer {
  List<Polygon> buildPolygons(List<GeoPointDto>? zonePolygon) {
    if (zonePolygon == null || zonePolygon.isEmpty) return [];
    return [
      Polygon(
        polygonId: 'arena_zone',
        points: zonePolygon.map((p) => LatLng(p.lat, p.lng)).toList(),
        strokeColor: AppColors.borderCyan.withOpacity(0.9),
        strokeWidth: 3,
        fillColor: AppColors.borderCyan.withOpacity(0.15),
      ),
    ];
  }

  List<Circle> buildCircles(GeoPointDto? jailCenter, double jailRadiusM) {
    if (jailCenter == null) return [];
    return [
      Circle(
        circleId: 'jail_zone',
        center: LatLng(jailCenter.lat, jailCenter.lng),
        radius: jailRadiusM,
        strokeColor: AppColors.purple.withOpacity(0.9),
        strokeWidth: 3,
        fillColor: AppColors.purple.withOpacity(0.2),
      ),
    ];
  }
}
