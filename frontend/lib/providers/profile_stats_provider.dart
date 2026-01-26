import 'package:flutter_riverpod/flutter_riverpod.dart';

class AchievementSummary {
  final String title;
  final bool unlocked;

  const AchievementSummary({required this.title, required this.unlocked});
}

class ProfileStats {
  final String policeRank;
  final int policeScore;
  final String thiefRank;
  final int thiefScore;
  final double avgCaught;
  final double avgRescued;
  final int totalPlaySec;
  final int mannerScore;
  final List<AchievementSummary> achievements;

  const ProfileStats({
    required this.policeRank,
    required this.policeScore,
    required this.thiefRank,
    required this.thiefScore,
    required this.avgCaught,
    required this.avgRescued,
    required this.totalPlaySec,
    required this.mannerScore,
    required this.achievements,
  });
}

final profileStatsProvider = Provider<ProfileStats>((ref) {
  return const ProfileStats(
    policeRank: '경사',
    policeScore: 1240,
    thiefRank: '전문털이범',
    thiefScore: 980,
    avgCaught: 2.6,
    avgRescued: 1.4,
    totalPlaySec: 13400,
    mannerScore: 80,
    achievements: [
      AchievementSummary(title: '첫 체포', unlocked: true),
      AchievementSummary(title: '첫 경기', unlocked: true),
      AchievementSummary(title: '3연승', unlocked: false),
      AchievementSummary(title: '구출 전문가', unlocked: false),
      AchievementSummary(title: '100km 달성', unlocked: false),
      AchievementSummary(title: '10경기 완주', unlocked: true),
    ],
  );
});
