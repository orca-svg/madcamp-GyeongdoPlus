import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String nickname;
  final String? profileImageUrl;

  // Rank and stats
  final String policeRank;
  final int policeScore;
  final String thiefRank;
  final int thiefScore;

  // Game stats
  final int totalGames;
  final int wins;
  final int losses;
  final double winRate;

  // Additional stats
  final int mannerScore;
  final int totalPlayTimeSec;

  const UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
    required this.policeRank,
    required this.policeScore,
    required this.thiefRank,
    required this.thiefScore,
    required this.totalGames,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.mannerScore,
    required this.totalPlayTimeSec,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Create a default/guest user
  factory UserModel.guest() => const UserModel(
    id: 'guest',
    email: 'guest@example.com',
    nickname: '게스트',
    policeRank: 'UNRANKED',
    policeScore: 0,
    thiefRank: 'UNRANKED',
    thiefScore: 0,
    totalGames: 0,
    wins: 0,
    losses: 0,
    winRate: 0.0,
    mannerScore: 100,
    totalPlayTimeSec: 0,
  );

  UserModel copyWith({
    String? id,
    String? email,
    String? nickname,
    String? profileImageUrl,
    String? policeRank,
    int? policeScore,
    String? thiefRank,
    int? thiefScore,
    int? totalGames,
    int? wins,
    int? losses,
    double? winRate,
    int? mannerScore,
    int? totalPlayTimeSec,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      policeRank: policeRank ?? this.policeRank,
      policeScore: policeScore ?? this.policeScore,
      thiefRank: thiefRank ?? this.thiefRank,
      thiefScore: thiefScore ?? this.thiefScore,
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      winRate: winRate ?? this.winRate,
      mannerScore: mannerScore ?? this.mannerScore,
      totalPlayTimeSec: totalPlayTimeSec ?? this.totalPlayTimeSec,
    );
  }
}
