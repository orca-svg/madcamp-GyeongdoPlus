import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

void showAppSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 2),
  bool isError = false,
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.clearSnackBars();

  final bottomInset = MediaQuery.of(context).padding.bottom;
  final navH = kBottomNavigationBarHeight;
  final fg = isError ? AppColors.red : AppColors.textPrimary;

  final snack = SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: duration,
    margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset + navH),
    backgroundColor: AppColors.surface1.withOpacity(0.92),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    action: action,
    content: Text(
      message,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: fg, fontWeight: FontWeight.w700),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snack);
  });
}
