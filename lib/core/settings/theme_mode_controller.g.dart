// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's light/dark/system preference, backed by Hive.
///
/// Seeded synchronously from [SettingsStore] so the very first frame already
/// paints in the student's chosen theme — no flash of the wrong brightness on
/// launch.

@ProviderFor(ThemeModeController)
final themeModeControllerProvider = ThemeModeControllerProvider._();

/// The app's light/dark/system preference, backed by Hive.
///
/// Seeded synchronously from [SettingsStore] so the very first frame already
/// paints in the student's chosen theme — no flash of the wrong brightness on
/// launch.
final class ThemeModeControllerProvider
    extends $NotifierProvider<ThemeModeController, ThemeMode> {
  /// The app's light/dark/system preference, backed by Hive.
  ///
  /// Seeded synchronously from [SettingsStore] so the very first frame already
  /// paints in the student's chosen theme — no flash of the wrong brightness on
  /// launch.
  ThemeModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeControllerHash();

  @$internal
  @override
  ThemeModeController create() => ThemeModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeControllerHash() =>
    r'7f3be9a1ed466e9c32702ee7733e43792d720118';

/// The app's light/dark/system preference, backed by Hive.
///
/// Seeded synchronously from [SettingsStore] so the very first frame already
/// paints in the student's chosen theme — no flash of the wrong brightness on
/// launch.

abstract class _$ThemeModeController extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
