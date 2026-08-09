import 'package:flutter/material.dart';

import '../theme/feedback_colors.dart';

enum AppFeedbackType { success, error, info }

void showAppFeedback(
  BuildContext context,
  String message, {
  AppFeedbackType type = AppFeedbackType.success,
}) {
  final colors = AppFeedbackColors.of(context);
  final (background, foreground) = switch (type) {
    AppFeedbackType.success => (
        colors.successBackground,
        colors.successForeground,
      ),
    AppFeedbackType.error => (
        colors.errorBackground,
        colors.errorForeground,
      ),
    AppFeedbackType.info => (
        colors.infoBackground,
        colors.infoForeground,
      ),
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w500,
          fontFamily: 'sans-serif',
        ),
      ),
      backgroundColor: background,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

enum CopyFeedbackType { key, value, path, all }

void showCopyFeedback(BuildContext context, CopyFeedbackType type) {
  final message = switch (type) {
    CopyFeedbackType.key => 'Key copied',
    CopyFeedbackType.value => 'Value copied',
    CopyFeedbackType.path => 'Path copied',
    CopyFeedbackType.all => 'JSON copied',
  };
  showAppFeedback(context, message, type: AppFeedbackType.success);
}
