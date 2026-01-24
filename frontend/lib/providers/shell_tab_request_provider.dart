import 'package:flutter_riverpod/flutter_riverpod.dart';

final shellTabRequestProvider = NotifierProvider<ShellTabRequestController, int?>(ShellTabRequestController.new);

class ShellTabRequestController extends Notifier<int?> {
  @override
  int? build() => null;

  void requestOffGameTab(int index) => state = index;

  int? consume() {
    final v = state;
    state = null;
    return v;
  }
}

