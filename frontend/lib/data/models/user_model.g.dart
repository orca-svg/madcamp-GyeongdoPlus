// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  nickname: json['nickname'] as String,
  profileImageUrl: json['profileImageUrl'] as String?,
  policeRank: json['policeRank'] as String,
  policeScore: (json['policeScore'] as num).toInt(),
  thiefRank: json['thiefRank'] as String,
  thiefScore: (json['thiefScore'] as num).toInt(),
  totalGames: (json['totalGames'] as num).toInt(),
  wins: (json['wins'] as num).toInt(),
  losses: (json['losses'] as num).toInt(),
  winRate: (json['winRate'] as num).toDouble(),
  mannerScore: (json['mannerScore'] as num).toInt(),
  totalPlayTimeSec: (json['totalPlayTimeSec'] as num).toInt(),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'nickname': instance.nickname,
  'profileImageUrl': instance.profileImageUrl,
  'policeRank': instance.policeRank,
  'policeScore': instance.policeScore,
  'thiefRank': instance.thiefRank,
  'thiefScore': instance.thiefScore,
  'totalGames': instance.totalGames,
  'wins': instance.wins,
  'losses': instance.losses,
  'winRate': instance.winRate,
  'mannerScore': instance.mannerScore,
  'totalPlayTimeSec': instance.totalPlayTimeSec,
};
