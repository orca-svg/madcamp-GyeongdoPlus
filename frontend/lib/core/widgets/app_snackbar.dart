import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ws_notice_provider.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class WsNoticeHost extends ConsumerStatefulWidget {
  final Widget child;

  const WsNoticeHost({super.key, required this.child});

  @override
  ConsumerState<WsNoticeHost> createState() => _WsNoticeHostState();
}

class _WsNoticeHostState extends ConsumerState<WsNoticeHost> {
  late final ProviderSubscription<WsNotice?> _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual<WsNotice?>(wsNoticeProvider, (prev, next) {
      if (next == null) return;
      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger == null) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(next.message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      ref.read(wsNoticeProvider.notifier).consume();
    });
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
