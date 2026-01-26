import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const bgTop = Color(0xFF0F172A); // #0F172A
  static const bgBottom = Color(0xFF070B16); // darker gradient tail

  // Surfaces / Cards
  static const surface1 = Color(0xFF172235); // #172235
  static const surface2 = Color(0xFF1B2B45); // #1B2B45

  // Border / Glow
  static const borderCyan = Color(0xFF27D7E5); // #27D7E5
  static const glowCyan = Color(0x4D27D7E5); // 30% opacity

  // Accent
  static const lime = Color(0xFF7CFF6B); // #7CFF6B
  static const red = Color(0xFFFF5C6C); // #FF5C6C
  static const purple = Color(0xFFA78BFA); // #A78BFA
  static const orange = Color(0xFFFFB85C); // #FFB85C

  // Text
  static const textPrimary = Color(0xFFEAF2FF); // #EAF2FF
  static const textSecondary = Color(0xFF9DB0D0); // #9DB0D0
  static const textMuted = Color(0xFF6E86A8); // #6E86A8

  // Divider / Outline
  static const outlineLow = Color(0x2A9DB0D0); // low alpha

  // Trend chip (bg + fg)
  static const chipPositiveBg = Color(0x1F7CFF6B);
  static const chipNegativeBg = Color(0x1FFF5C6C);
  static const chipPositiveFg = lime;
  static const chipNegativeFg = red;

  // Graph gradients
  static const graphCyan = borderCyan;
  static const graphLime = lime;
  static const graphBlue = Color(0xFF3B82F6);
  static const graphYellow = Color(0xFFFFD86B);

  // Backward-compatible aliases (keep existing names used across code)
  static const surface = surface1;
  static const ally = borderCyan;
  static const enemy = red;
  static const safe = lime;
  static const warn = orange;
  static const border = borderCyan;
  static const glow = glowCyan;
}
