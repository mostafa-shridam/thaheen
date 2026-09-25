import 'package:flutter/material.dart';

/// Raw palette from `docs/DESIGN_SYSTEM.md`.
///
/// Nothing outside this file should spell a hex value. Widgets read semantic
/// colours from [AppPalette] (via `Theme.of(context).palette`) so light and
/// dark stay in step.
abstract final class AppColors {
  // --- Brand ---
  static const Color primary = Color(0xFF006699);
  static const Color secondary = Color(0xFF00A88F);

  // --- Light surfaces ---
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color lockedLight = Color(0xFFCBD5E1);
  static const Color borderLight = Color(0xFFE2E8F0);

  // --- Dark surfaces (bonus dark mode; derived from the same brand hues) ---
  static const Color primaryDark = Color(0xFF3FA3D1);
  static const Color secondaryDark = Color(0xFF2FD0B4);
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color surfaceDark = Color(0xFF151F31);
  static const Color textPrimaryDark = Color(0xFFE8EEF7);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color lockedDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF243347);

  // --- Feedback ---
  static const Color error = Color(0xFFE11D48);
  static const Color errorDark = Color(0xFFFB7185);
}

/// Semantic colours the Material [ColorScheme] has no slot for.
///
/// `locked` and `success` are domain concepts here — a locked lesson tile and a
/// completed check are the two states a student reads fastest — so they get
/// first-class names instead of being approximated with `outline`/`tertiary`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.locked,
    required this.success,
    required this.border,
    required this.textSecondary,
  });

  static const AppPalette light = AppPalette(
    locked: AppColors.lockedLight,
    success: AppColors.secondary,
    border: AppColors.borderLight,
    textSecondary: AppColors.textSecondaryLight,
  );

  static const AppPalette dark = AppPalette(
    locked: AppColors.lockedDark,
    success: AppColors.secondaryDark,
    border: AppColors.borderDark,
    textSecondary: AppColors.textSecondaryDark,
  );

  final Color locked;
  final Color success;
  final Color border;
  final Color textSecondary;

  @override
  AppPalette copyWith({
    Color? locked,
    Color? success,
    Color? border,
    Color? textSecondary,
  }) =>
      AppPalette(
        locked: locked ?? this.locked,
        success: success ?? this.success,
        border: border ?? this.border,
        textSecondary: textSecondary ?? this.textSecondary,
      );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      locked: Color.lerp(locked, other.locked, t)!,
      success: Color.lerp(success, other.success, t)!,
      border: Color.lerp(border, other.border, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }
}

/// `Theme.of(context).palette` — shorter than the full extension lookup and
/// impossible to get wrong.
extension AppPaletteAccess on ThemeData {
  AppPalette get palette => extension<AppPalette>() ?? AppPalette.light;
}
