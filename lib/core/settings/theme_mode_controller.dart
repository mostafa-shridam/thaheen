import 'package:flutter/material.dart' show ThemeMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:thaheen_task/core/settings/settings_store.dart';

part 'theme_mode_controller.g.dart';

/// The app's light/dark/system preference, backed by Hive.
///
/// Seeded synchronously from [SettingsStore] so the very first frame already
/// paints in the student's chosen theme — no flash of the wrong brightness on
/// launch.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() => SettingsStore.readThemeMode();

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await SettingsStore.writeThemeMode(mode);
  }
}
