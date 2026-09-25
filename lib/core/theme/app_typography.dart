import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';

/// Type scale from `docs/DESIGN_SYSTEM.md`, expressed as a Material [TextTheme].
///
/// The design system names four roles; they map onto Material slots as:
///
/// | Design role              | Material slot   | Size | Weight |
/// |--------------------------|-----------------|------|--------|
/// | Heading 1 / course title | `titleLarge`    | 20   | 700    |
/// | Heading 2 / section      | `titleMedium`   | 16   | 600    |
/// | Body / lesson title      | `bodyMedium`    | 14   | 500    |
/// | Caption / meta           | `bodySmall`     | 12   | 400    |
///
/// Sizes are in logical pixels at the 390dp baseline; `responsive_framework`
/// scales the surrounding layout, and the OS text-scale factor still applies.
abstract final class AppTypography {
  static const String fontFamily = 'Cairo';

  /// Cairo's Arabic glyphs sit tall; the default 1.0 leading crowds them.
  static const double _arabicLineHeight = 1.55;

  static TextTheme textTheme({required Color primary, required Color secondary}) {
    TextStyle style(double size, FontWeight weight, Color color) => TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: _arabicLineHeight,
        );

    return TextTheme(
      // Course titles and screen headlines.
      titleLarge: style(20, FontWeight.w700, primary),
      // Section titles.
      titleMedium: style(16, FontWeight.w600, primary),
      // Buttons and emphasised inline labels.
      titleSmall: style(14, FontWeight.w600, primary),
      // Lesson titles and body copy.
      bodyMedium: style(14, FontWeight.w500, primary),
      // Instructor, duration, metadata.
      bodySmall: style(12, FontWeight.w400, secondary),
      // Large numerals (progress %, timestamps) — tabular-friendly.
      headlineSmall: style(24, FontWeight.w700, primary),
      labelLarge: style(14, FontWeight.w600, primary),
      labelMedium: style(12, FontWeight.w500, secondary),
    );
  }

  static TextTheme get light => textTheme(
        primary: AppColors.textPrimaryLight,
        secondary: AppColors.textSecondaryLight,
      );

  static TextTheme get dark => textTheme(
        primary: AppColors.textPrimaryDark,
        secondary: AppColors.textSecondaryDark,
      );
}
