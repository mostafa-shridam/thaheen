import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
// `Override` is re-exported here; `flutter_riverpod` does not expose it.
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:thaheen_task/core/localization/app_locales.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/theme/app_theme.dart';
import 'package:thaheen_task/generated/codegen_loader.g.dart';

/// Boots the binding for a test file.
///
/// Deliberately does **not** call `EasyLocalization.ensureInitialized()`, because
/// `main.dart` does not either — the tests must exercise the same startup path
/// the app uses. That call exists only to populate two statics from
/// SharedPreferences and the platform locale; passing a non-null `startLocale`
/// (as both the app and [pumpAppWidget] do) takes a branch that reads neither.
Future<void> initTestLocalization() async {
  TestWidgetsFlutterBinding.ensureInitialized();
}

/// Pumps [child] inside the same localisation, theme and Riverpod stack the
/// real app uses.
///
/// Translations come from [CodegenLoader], which is compiled into the binary —
/// so tests read the real Arabic and English copy without loading any asset.
Future<void> pumpAppWidget(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const <Override>[],
  Locale locale = AppLocales.fallback,
  Size surfaceSize = const Size(390, 1600),
}) async {
  // The default 800x600 test window is neither phone-shaped nor tall enough for
  // a lazy list to build more than one card. 390 wide is the design baseline
  // from docs/DESIGN_SYSTEM.md; the extra height keeps scrolling out of the
  // assertions.
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: AppLocales.translationsPath,
        startLocale: locale,
        fallbackLocale: AppLocales.fallback,
        assetLoader: const CodegenLoader(),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: AppTheme.light,
            // Mirrors `app.dart`: pages read `ResponsiveValue`, which asserts
            // unless a ResponsiveBreakpoints ancestor exists.
            builder: (context, navigator) => ResponsiveBreakpoints.builder(
              breakpoints: AppBreakpoints.all,
              child: navigator ?? const SizedBox.shrink(),
            ),
            home: child,
          ),
        ),
      ),
    ),
  );

  // EasyLocalization resolves its bundle asynchronously on the first frame.
  await tester.pumpAndSettle();
}
