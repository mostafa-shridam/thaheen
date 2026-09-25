import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thaheen_task/app.dart';
import 'package:thaheen_task/core/localization/app_locales.dart';
import 'package:thaheen_task/core/settings/settings_store.dart';
import 'package:thaheen_task/core/storage/hive_boxes.dart';
import 'package:thaheen_task/generated/codegen_loader.g.dart';

/// Everything that has to finish before the first frame.
///
/// The two steps are independent of each other, so they run concurrently rather
/// than in sequence. Both settle before the tree is built, which is what the
/// ordering below actually depends on:
///
/// * [HiveBoxes.init] completes before [SettingsStore] is asked for the saved
///   language. It never throws — a device where storage is unavailable still
///   launches, just without persistence.
///
/// Portrait is the app-wide default; the lesson player is the only screen that
/// asks for landscape, and it restores this on the way out.
Future<void> firstInit() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait<void>(<Future<void>>[
    HiveBoxes.init(),
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  ]);
}

void main() {
  runZonedGuarded(
    () async {
      await firstInit();

      runApp(
        ProviderScope(
          child: EasyLocalization(
            supportedLocales: AppLocales.supported,
            path: AppLocales.translationsPath,
            fallbackLocale: AppLocales.fallback,

            // Arabic-first in the strong sense: it is both where a fresh
            // install starts and where an unsupported device language lands.
            startLocale: SettingsStore.readLocale(),

            // Translations are compiled into the binary rather than read from
            // the asset bundle at runtime — one less file to fail on a cold start.
            assetLoader: const CodegenLoader(),

            // Locale persistence lives in Hive (SettingsStore). `false` keeps
            // easy_localization's own SharedPreferences store closed — this
            // project is Hive-only.
            //
            // `EasyLocalization.ensureInitialized()` is deliberately not called
            // either. In 3.0.8 it populates two statics: the SharedPreferences
            // saved locale (which we never write) and `_deviceLocale`, a `late`
            // field read only when no `startLocale` is supplied.
            //
            // INVARIANT: `startLocale` above must stay non-null. `readLocale()`
            // returns a non-nullable `Locale` and falls back to Arabic for an
            // unrecognised code, so the branch that would touch the
            // uninitialised `_deviceLocale` is unreachable. Locked down by
            // test/localization/app_locales_test.dart — if that invariant ever
            // breaks, this becomes a LateInitializationError on launch.
            saveLocale: false,

            // Translation files are `ar.json` / `en.json`, not `ar-SA.json`.
            useOnlyLangCode: true,

            child: const ThaheenApp(),
          ),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}
