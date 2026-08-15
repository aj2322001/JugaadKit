import 'package:flutter/material.dart';

class AppFeedbackColors extends ThemeExtension<AppFeedbackColors> {
  const AppFeedbackColors({
    required this.successBackground,
    required this.successForeground,
    required this.errorBackground,
    required this.errorForeground,
    required this.infoBackground,
    required this.infoForeground,
    required this.warningBackground,
    required this.warningForeground,
  });

  final Color successBackground;
  final Color successForeground;
  final Color errorBackground;
  final Color errorForeground;
  final Color infoBackground;
  final Color infoForeground;
  final Color warningBackground;
  final Color warningForeground;

  static const light = AppFeedbackColors(
    successBackground: Color(0xFFDCFCE7),
    successForeground: Color(0xFF15803D),
    errorBackground: Color(0xFFFEE2E2),
    errorForeground: Color(0xFFB91C1C),
    infoBackground: Color(0xFFDBEAFE),
    infoForeground: Color(0xFF1D4ED8),
    warningBackground: Color(0xFFFEF9C3),
    warningForeground: Color(0xFFCA8A04),
  );

  static const dark = AppFeedbackColors(
    successBackground: Color(0xFF14532D),
    successForeground: Color(0xFF4ADE80),
    errorBackground: Color(0xFF7F1D1D),
    errorForeground: Color(0xFFF87171),
    infoBackground: Color(0xFF1E3A8A),
    infoForeground: Color(0xFF60A5FA),
    warningBackground: Color(0xFF422006),
    warningForeground: Color(0xFFFACC15),
  );

  static AppFeedbackColors of(BuildContext context) {
    return Theme.of(context).extension<AppFeedbackColors>() ?? light;
  }

  @override
  AppFeedbackColors copyWith({
    Color? successBackground,
    Color? successForeground,
    Color? errorBackground,
    Color? errorForeground,
    Color? infoBackground,
    Color? infoForeground,
    Color? warningBackground,
    Color? warningForeground,
  }) {
    return AppFeedbackColors(
      successBackground: successBackground ?? this.successBackground,
      successForeground: successForeground ?? this.successForeground,
      errorBackground: errorBackground ?? this.errorBackground,
      errorForeground: errorForeground ?? this.errorForeground,
      infoBackground: infoBackground ?? this.infoBackground,
      infoForeground: infoForeground ?? this.infoForeground,
      warningBackground: warningBackground ?? this.warningBackground,
      warningForeground: warningForeground ?? this.warningForeground,
    );
  }

  @override
  AppFeedbackColors lerp(ThemeExtension<AppFeedbackColors>? other, double t) {
    if (other is! AppFeedbackColors) {
      return this;
    }

    return AppFeedbackColors(
      successBackground:
          Color.lerp(successBackground, other.successBackground, t)!,
      successForeground:
          Color.lerp(successForeground, other.successForeground, t)!,
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t)!,
      errorForeground: Color.lerp(errorForeground, other.errorForeground, t)!,
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      infoForeground: Color.lerp(infoForeground, other.infoForeground, t)!,
      warningBackground:
          Color.lerp(warningBackground, other.warningBackground, t)!,
      warningForeground:
          Color.lerp(warningForeground, other.warningForeground, t)!,
    );
  }
}
