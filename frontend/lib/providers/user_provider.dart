import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dto/user_dto.dart';
import 'app_providers.dart';

// User State
class UserState {
  final bool isLoading;
  final String? errorMessage;
  final MyProfileDataDto? profile;
  final List<MatchRecordDto> matchHistory;
  final bool hasMoreHistory;
  final int currentPage;

  const UserState({
    this.isLoading = false,
    this.errorMessage,
    this.profile,
    this.matchHistory = const [],
    this.hasMoreHistory = true,
    this.currentPage = 1,
  });

  UserState copyWith({
    bool? isLoading,
    String? errorMessage,
    MyProfileDataDto? profile,
    List<MatchRecordDto>? matchHistory,
    bool? hasMoreHistory,
    int? currentPage,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      profile: profile ?? this.profile,
      matchHistory: matchHistory ?? this.matchHistory,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  // Getters for UI convenience
  String get nickname => profile?.user.nickname ?? 'Guest';
  String? get profileImage => profile?.user.profileImage;
  int get policeMmr => profile?.stat.policeMmr ?? 0;
  int get thiefMmr => profile?.stat.thiefMmr ?? 0;
  int get totalCatch => profile?.stat.totalCatch ?? 0;
  int get totalSurvival => profile?.stat.totalSurvival ?? 0;
  double get totalDistance => profile?.stat.totalDistance ?? 0.0;
  int get integrityScore => profile?.stat.integrityScore ?? 0;
  List<AchievementDto> get achievements => profile?.achievements ?? [];
}

// User Provider
class UserController extends Notifier<UserState> {
  @override
  UserState build() {
    return const UserState();
  }

  Future<void> fetchMyProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final userRepo = ref.read(userRepositoryProvider);
    final result = await userRepo.getMyProfile();

    if (result.success && result.data != null) {
      state = state.copyWith(
        isLoading: false,
        profile: result.data,
        errorMessage: null,
      );
      debugPrint('[USER] Profile loaded: ${result.data!.user.nickname}');
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage ?? 'Failed to load profile',
      );
      debugPrint('[USER] Profile load failed: ${result.errorMessage}');
    }
  }

  Future<void> fetchMatchHistory({int page = 1, int limit = 20}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final userRepo = ref.read(userRepositoryProvider);
    final result = await userRepo.getMatchHistory(page: page, limit: limit);

    if (result.success && result.data != null) {
      final newHistory = result.data!;
      final updatedHistory = page == 1
          ? newHistory
          : [...state.matchHistory, ...newHistory];

      state = state.copyWith(
        isLoading: false,
        matchHistory: updatedHistory,
        hasMoreHistory: newHistory.length >= limit,
        currentPage: page,
        errorMessage: null,
      );
      debugPrint('[USER] Match history loaded: ${newHistory.length} records');
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage ?? 'Failed to load match history',
      );
      debugPrint('[USER] Match history load failed: ${result.errorMessage}');
    }
  }

  Future<bool> updateProfile({String? nickname, String? profileImage}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final userRepo = ref.read(userRepositoryProvider);
    final result = await userRepo.updateProfile(
      nickname: nickname,
      profileImage: profileImage,
    );

    if (result.success && result.data != null) {
      // Refresh profile after update
      await fetchMyProfile();
      debugPrint('[USER] Profile updated: ${result.data!.nickname}');
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage ?? 'Failed to update profile',
      );
      debugPrint('[USER] Profile update failed: ${result.errorMessage}');
      return false;
    }
  }

  void loadMoreHistory() {
    if (!state.hasMoreHistory || state.isLoading) return;
    fetchMatchHistory(page: state.currentPage + 1);
  }

  void reset() {
    state = const UserState();
  }
}

// Provider
final userProvider = NotifierProvider<UserController, UserState>(
  UserController.new,
);
