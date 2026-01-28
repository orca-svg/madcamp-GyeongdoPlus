class RankUtils {
  static String getPoliceRankTitle(int score) {
    if (score >= 3000) return '총경';
    if (score >= 1500) return '경감';
    if (score >= 600) return '경사';
    return '순경';
  }

  static String getThiefRankTitle(int score) {
    if (score >= 3000) return '팬텀';
    if (score >= 1500) return '마스터';
    if (score >= 600) return '엑스퍼트';
    return '루키';
  }
}
