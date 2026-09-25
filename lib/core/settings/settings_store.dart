import 'dart:ui' show Locale;

import 'package:flutter/material.dart' show ThemeMode;
import 'package:thaheen_task/core/localization/app_locales.dart';
import 'package:thaheen_task/core/storage/hive_boxes.dart';

/// Plain, synchronous read/write access to user preferences in Hive.
///
/// Deliberately not a provider: `main()` needs the saved language *before* the
/// widget tree (and therefore any `ProviderScope`) exists, so it can hand
/// `easy_localization` a `startLocale`. The Riverpod layer on top of this is
/// `SettingsController`.
///
/// Every method is null-safe against a closed box, so a device where Hive
/// failed to open still runs with defaults.
abstract final class SettingsStore {
  static const String _localeKey = 'locale.languageCode';
  static const String _themeKey = 'theme.mode';
  static const String _playbackSpeedKey = 'player.speed';

  // --- Locale -------------------------------------------------------------

  /// The saved language, or Arabic when nothing has been chosen yet.
  ///
  /// This is what makes the app Arabic-first on a fresh install regardless of
  /// the device language.
  static Locale readLocale() =>
      AppLocales.fromLanguageCode(HiveBoxes.settingsBox?.get(_localeKey));

  static Future<void> writeLocale(Locale locale) async =>
      HiveBoxes.settingsBox?.put(_localeKey, locale.languageCode);

  // --- Theme --------------------------------------------------------------

  static ThemeMode readThemeMode() => switch (HiveBoxes.settingsBox?.get(_themeKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static Future<void> writeThemeMode(ThemeMode mode) async =>
      HiveBoxes.settingsBox?.put(_themeKey, mode.name);

  // --- Playback speed -----------------------------------------------------

  /// Last playback speed the student chose, defaulting to normal speed.
  ///
  /// Remembering this across lessons is one of the task's bonus items; keeping
  /// it beside the other preferences avoids a third storage concept.
  static double readPlaybackSpeed() {
    final raw = HiveBoxes.settingsBox?.get(_playbackSpeedKey);
    final parsed = raw == null ? null : double.tryParse(raw);
    return parsed == null || parsed <= 0 ? 1 : parsed;
  }

  static Future<void> writePlaybackSpeed(double speed) async =>
      HiveBoxes.settingsBox?.put(_playbackSpeedKey, speed.toString());
}
