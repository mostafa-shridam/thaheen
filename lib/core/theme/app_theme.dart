import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';
import 'package:thaheen_task/core/theme/app_typography.dart';

/// Builds the light and dark [ThemeData] for the app.
///
/// Component defaults are set here once — card radius, tile padding, button
/// shape — so feature widgets stay declarative and no screen re-specifies the
/// design system locally.
abstract final class AppTheme {
  /// `BorderRadius.circular(12)` per the design system.
  static const double cardRadius = 12;
  static const double controlRadius = 10;

  static ThemeData get light => _build(
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.backgroundLight,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        error: AppColors.error,
        palette: AppPalette.light,
        textTheme: AppTypography.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        background: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.errorDark,
        palette: AppPalette.dark,
        textTheme: AppTypography.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color error,
    required AppPalette palette,
    required TextTheme textTheme,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLowest: background,
      surfaceContainerHighest: palette.border,
      outline: palette.border,
      error: error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      extensions: <ThemeExtension<Object?>>[palette],

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: onSurface),
      ),

      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: palette.border),
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        titleTextStyle: textTheme.bodyMedium,
        subtitleTextStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: palette.border,
        linearMinHeight: 6,
      ),

      dividerTheme: DividerThemeData(color: palette.border, space: 1, thickness: 1),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
    );
  }
}
