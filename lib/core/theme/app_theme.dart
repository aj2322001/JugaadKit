import 'package:flutter/material.dart';

import '../../features/json_jugaad/theme/json_syntax_colors.dart';
import 'feedback_colors.dart';

abstract final class AppTheme {
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _darkBorder = Color(0xFF334155);

  static ThemeData light() => _buildTheme(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6B93),
          brightness: Brightness.light,
          surface: const Color(0xFFF8FAFC),
        ).copyWith(
          outline: _lightBorder,
          outlineVariant: _lightBorder,
        ),
        cardColor: Colors.white,
        inputFillColor: Colors.white,
        borderColor: _lightBorder,
        syntaxColors: JsonSyntaxColors.light,
        feedbackColors: AppFeedbackColors.light,
      );

  static ThemeData dark() => _buildTheme(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38BDF8),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
        ).copyWith(
          outline: _darkBorder,
          outlineVariant: _darkBorder,
        ),
        cardColor: const Color(0xFF1E293B),
        inputFillColor: const Color(0xFF0F172A),
        borderColor: _darkBorder,
        syntaxColors: JsonSyntaxColors.dark,
        feedbackColors: AppFeedbackColors.dark,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color cardColor,
    required Color inputFillColor,
    required Color borderColor,
    required JsonSyntaxColors syntaxColors,
    required AppFeedbackColors feedbackColors,
  }) {
    final borderSide = BorderSide(color: borderColor);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: 'monospace',
      textTheme: _textTheme(brightness),
      extensions: [syntaxColors, feedbackColors],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderSide,
        ),
        color: cardColor,
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = Typography.material2021().englishLike;
    final bodyColor = brightness == Brightness.light
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return base.copyWith(
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w700,
        color: bodyColor,
        letterSpacing: -0.5,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w600,
        color: bodyColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w600,
        color: bodyColor,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: 'monospace',
        color: bodyColor,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: 'sans-serif',
        color: bodyColor.withValues(alpha: 0.85),
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: 'sans-serif',
        color: bodyColor.withValues(alpha: 0.65),
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: 'sans-serif',
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
