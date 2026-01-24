import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../watch/watch_bridge.dart';

final watchConnectedProvider = NotifierProvider<WatchConnectedController, bool>(WatchConnectedController.new);

class WatchConnectedController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> init() async {
    await WatchBridge.init();
    state = await WatchBridge.isPairedOrConnected();
  }

  Future<void> refresh() async {
    state = await WatchBridge.isPairedOrConnected();
  }
}
