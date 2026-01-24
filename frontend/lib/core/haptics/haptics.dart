import 'dart:async';

import 'package:flutter/services.dart';

enum HapticPattern {
  captureConfirmed,
  rescueSuccess,
  enemyPing,
  captureNearlyDone,
  warning,
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
    }
  }
}

