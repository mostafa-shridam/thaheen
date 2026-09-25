import 'dart:io';

// `intl`, re-exported by easy_localization, also defines a `TextDirection`;
// hide it so `TextDirection.rtl` means Flutter's.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:thaheen_task/core/localization/app_locales.dart';
import 'package:thaheen_task/core/widgets/app_empty_view.dart';
import 'package:thaheen_task/core/widgets/app_error_view.dart';
import 'package:thaheen_task/features/lms/data/datasources/course_asset_data_source.dart';
import 'package:thaheen_task/features/lms/presentation/pages/courses_page.dart';
import 'package:thaheen_task/features/lms/presentation/providers/catalogue_providers.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_card.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

import '../fixtures/app_harness.dart';
import '../fixtures/fake_asset_bundle.dart';

/// Widget coverage for the courses list: its four states, and the RTL/LTR flip.
void main() {
  setUpAll(initTestLocalization);

  /// Serves [catalogue] as `courses.json`; `null` means the asset is missing.
  Override catalogueOverride(String? catalogue) =>
      courseAssetDataSourceProvider.overrideWithValue(
        CourseAssetDataSource(
          bundle: FakeAssetBundle(<String, String>{
            CourseAssetDataSource.assetPath: ?catalogue,
          }),
        ),
      );

  String readRealCatalogue() =>
      File(CourseAssetDataSource.assetPath).readAsStringSync();

  testWidgets('renders a card per course from the real catalogue', (tester) async {
    await pumpAppWidget(
      tester,
      const CoursesPage(),
      overrides: <Override>[catalogueOverride(readRealCatalogue())],
    );

    expect(find.byType(CourseCard), findsNWidgets(2));
    expect(find.text('مقدمة في التشريح'), findsOneWidget);
    expect(find.text('د. سارة الحربي'), findsOneWidget);
  });

  testWidgets('an empty catalogue shows the empty state, not an error',
      (tester) async {
    await pumpAppWidget(
      tester,
      const CoursesPage(),
      overrides: <Override>[catalogueOverride('{"courses":[]}')],
    );

    expect(find.byType(AppEmptyView), findsOneWidget);
    expect(find.byType(AppErrorView), findsNothing);
    expect(find.text(LocaleKeys.courses_empty.tr()), findsOneWidget);
  });

  testWidgets('a missing catalogue shows the error card with a retry',
      (tester) async {
    await pumpAppWidget(
      tester,
      const CoursesPage(),
      overrides: <Override>[catalogueOverride(null)],
    );

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text(LocaleKeys.common_retry.tr()), findsOneWidget);
    // The whole point: a broken asset must never surface as a red screen.
    expect(tester.takeException(), isNull);
  });

  testWidgets('corrupt JSON is handled as an error, not a crash', (tester) async {
    await pumpAppWidget(
      tester,
      const CoursesPage(),
      overrides: <Override>[catalogueOverride('{ not json')],
    );

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('direction follows the locale', () {
    testWidgets('Arabic lays out right-to-left', (tester) async {
      await pumpAppWidget(
        tester,
        const CoursesPage(),
        // The harness default is Arabic — the app's fallback and start locale.
        overrides: <Override>[catalogueOverride(readRealCatalogue())],
      );

      // No hand-placed Directionality anywhere: WidgetsApp derives it from the
      // active locale, which is what lets the language switch flip the layout.
      final context = tester.element(find.byType(CourseCard).first);
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('English lays out left-to-right', (tester) async {
      await pumpAppWidget(
        tester,
        const CoursesPage(),
        overrides: <Override>[catalogueOverride(readRealCatalogue())],
        locale: AppLocales.english,
      );

      final context = tester.element(find.byType(CourseCard).first);
      expect(Directionality.of(context), TextDirection.ltr);
      expect(find.text('My courses'), findsOneWidget);
    });
  });
}
