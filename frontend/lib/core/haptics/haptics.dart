import 'dart:async';

import 'package:flutter/services.dart';

enum HapticPattern {
  captureConfirmed,
  rescueSuccess,
  enemyPing,
  captureNearlyDone,
  warning,
  // Proximity-based haptics for auto-arrest
  proximityMedium,   // 5m zone - Light tick
  proximityClose,    // 3m zone - Medium click
  proximityExtreme,  // 1m zone - Heavy heartbeat
}

class Haptics {
  static Future<void> pattern(HapticPattern p) async {
    switch (p) {
      case HapticPattern.captureConfirmed:
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.mediumImpact();
        return;
      case HapticPattern.rescueSuccess:
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await HapticFeedback.selectionClick();
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await HapticFeedback.selectionClick();
        return;
      case HapticPattern.enemyPing:
        await HapticFeedback.selectionClick();
        return;
      case HapticPattern.captureNearlyDone:
        await HapticFeedback.lightImpact();
        return;
      case HapticPattern.warning:
        await HapticFeedback.selectionClick();
        return;
      case HapticPattern.proximityMedium:
        await HapticFeedback.selectionClick();
        return;
      case HapticPattern.proximityClose:
        await HapticFeedback.mediumImpact();
        return;
      case HapticPattern.proximityExtreme:
        // Heartbeat pattern: Heavy-Medium-Medium
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.mediumImpact();
        return;
    }
  }
}

