import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../providers/ws_ui_status_provider.dart';

class WsStatusPill extends StatefulWidget {
  final WsUiStatusModel model;
  final VoidCallback? onReconnect;

  const WsStatusPill({
    super.key,
    required this.model,
    required this.onReconnect,
  });

  @override
  State<WsStatusPill> createState() => _WsStatusPillState();
}

class _WsStatusPillState extends State<WsStatusPill> {
  Timer? _muteTimer;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _syncMuteTimer();
  }

  @override
  void didUpdateWidget(covariant WsStatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.status != widget.model.status) {
      _muted = false;
      _syncMuteTimer();
    }
  }

  void _syncMuteTimer() {
    _muteTimer?.cancel();
    _muteTimer = null;
    if (!widget.model.isSynced) return;
    _muteTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _muted = true);
    });
  }

  @override
  void dispose() {
    _muteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    final canReconnect = m.showReconnect && widget.onReconnect != null;
    final opacity = _muted ? 0.55 : 1.0;

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: canReconnect ? widget.onReconnect : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface2.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: m.dotColor.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: m.dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                m.text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              if (canReconnect) ...[
                const SizedBox(width: 10),
                Text(
                  '재연결',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.borderCyan,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

