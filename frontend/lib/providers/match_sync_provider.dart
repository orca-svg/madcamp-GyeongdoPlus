import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../net/ws/dto/match_state.dart';
import '../net/ws/dto/radar_ping.dart';
import '../net/ws/ws_envelope.dart';

class MatchSyncState {
  final WsEnvelope<MatchStateDto>? lastMatchState;
  final WsEnvelope<RadarPingPayload>? lastRadarPing;
  final String? lastJsonPreview;

  const MatchSyncState({
    required this.lastMatchState,
    required this.lastRadarPing,
    required this.lastJsonPreview,
  });

  factory MatchSyncState.initial() => const MatchSyncState(
        lastMatchState: null,
        lastRadarPing: null,
        lastJsonPreview: null,
      );

  MatchSyncState copyWith({
    WsEnvelope<MatchStateDto>? lastMatchState,
    WsEnvelope<RadarPingPayload>? lastRadarPing,
    String? lastJsonPreview,
  }) {
    return MatchSyncState(
      lastMatchState: lastMatchState ?? this.lastMatchState,
      lastRadarPing: lastRadarPing ?? this.lastRadarPing,
      lastJsonPreview: lastJsonPreview ?? this.lastJsonPreview,
    );
  }
}

final matchSyncProvider = NotifierProvider<MatchSyncController, MatchSyncState>(MatchSyncController.new);

class MatchSyncController extends Notifier<MatchSyncState> {
  @override
  MatchSyncState build() => MatchSyncState.initial();

  void setMatchState(WsEnvelope<MatchStateDto> env) {
    state = state.copyWith(
      lastMatchState: env,
      lastJsonPreview: jsonEncode(env.toJson((p) => p.toJson())),
    );
  }

  void setRadarPing(WsEnvelope<RadarPingPayload> env) {
    state = state.copyWith(
      lastRadarPing: env,
      lastJsonPreview: jsonEncode(env.toJson((p) => p.toJson())),
    );
  }

  void clearPreview() => state = state.copyWith(lastJsonPreview: '');
}

