import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../watch/watch_bridge.dart';

final watchConnectedProvider = StateNotifierProvider<WatchConnectedController, bool>((ref) {
  return WatchConnectedController();
});

class WatchConnectedController extends StateNotifier<bool> {
  WatchConnectedController() : super(false);

  Future<void> init() async {
    await WatchBridge.init();
    state = await WatchBridge.isPairedOrConnected();
  }

  Future<void> refresh() async {
    state = await WatchBridge.isPairedOrConnected();
  }
}
