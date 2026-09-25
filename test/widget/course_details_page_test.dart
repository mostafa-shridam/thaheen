import 'dart:io';

// `intl`, re-exported by easy_localization, also defines a `TextDirection`;
// hide it so `TextDirection.rtl` means Flutter's.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:thaheen_task/features/lms/data/datasources/course_asset_data_source.dart';
import 'package:thaheen_task/features/lms/data/datasources/progress_local_data_source.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_progress_model.dart';
import 'package:thaheen_task/features/lms/presentation/pages/course_details_page.dart';
import 'package:thaheen_task/features/lms/presentation/providers/catalogue_providers.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/lesson_tile.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

import '../fixtures/app_harness.dart';
import '../fixtures/fake_asset_bundle.dart';

/// Serves preset progress without touching Hive.
class _FakeProgressSource implements ProgressLocalDataSource {
  const _FakeProgressSource(this.seed);

  final ProgressByLesson seed;

  @override
  ProgressByLesson readAll() => seed;

  @override
  LessonProgressModel readOne(String lessonId) => seed.forLesson(lessonId);

  @override
  Future<void> write(LessonProgressModel progress) async {}

  @override
  Future<void> clear() async {}
}

/// Covers the student-facing half of the sequential-unlock rule: what a locked
/// lesson looks like, and what it says when tapped.
void main() {
  setUpAll(initTestLocalization);

  // From the real catalogue: the first two lessons of the anatomy course.
  const courseId = 'anatomy-101';
  const firstLesson = 'تركيب العظام ووظائفها';
  const secondLesson = 'المفاصل والغضاريف';

  List<Override> overridesWith(ProgressByLesson progress) => <Override>[
        courseAssetDataSourceProvider.overrideWithValue(
          CourseAssetDataSource(
            bundle: FakeAssetBundle(<String, String>{
              CourseAssetDataSource.assetPath:
                  File(CourseAssetDataSource.assetPath).readAsStringSync(),
            }),
          ),
        ),
        progressLocalDataSourceProvider
            .overrideWithValue(_FakeProgressSource(progress)),
      ];

  const completedFirst = <String, LessonProgressModel>{
    'anatomy-101-l1': LessonProgressModel(
      lessonId: 'anatomy-101-l1',
      positionSec: 10,
      watchedSec: 10,
      durationSec: 10,
      completed: true,
    ),
  };

  testWidgets('lists every lesson in the course', (tester) async {
    await pumpAppWidget(
      tester,
      const CourseDetailsPage(courseId: courseId),
      overrides: overridesWith(const <String, LessonProgressModel>{}),
    );

    expect(find.byType(LessonTile), findsNWidgets(5));
    expect(find.text(firstLesson), findsOneWidget);
  });

  testWidgets('a fresh course shows lesson one open and lesson two locked',
      (tester) async {
    await pumpAppWidget(
      tester,
      const CourseDetailsPage(courseId: courseId),
      overrides: overridesWith(const <String, LessonProgressModel>{}),
    );

    expect(find.text(LocaleKeys.lesson_status_notStarted.tr()), findsOneWidget);
    // Lessons 2-5 are all shut behind the one before them.
    expect(find.text(LocaleKeys.lesson_status_locked.tr()), findsNWidgets(4));
  });

  testWidgets('tapping a locked lesson names the lesson that unlocks it',
      (tester) async {
    await pumpAppWidget(
      tester,
      const CourseDetailsPage(courseId: courseId),
      overrides: overridesWith(const <String, LessonProgressModel>{}),
    );

    await tester.tap(find.text(secondLesson));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // A dead end is turned into an instruction: finish *this* lesson next.
    expect(
      find.text(
        LocaleKeys.lesson_lockedMessage
            .tr(namedArgs: <String, String>{'title': firstLesson}),
      ),
      findsOneWidget,
    );
  });

  testWidgets('completing lesson one unlocks exactly lesson two',
      (tester) async {
    await pumpAppWidget(
      tester,
      const CourseDetailsPage(courseId: courseId),
      overrides: overridesWith(completedFirst),
    );

    expect(find.text(LocaleKeys.lesson_status_completed.tr()), findsOneWidget);
    expect(find.text(LocaleKeys.lesson_status_notStarted.tr()), findsOneWidget);
    // Three still locked — unlocking never skips ahead.
    expect(find.text(LocaleKeys.lesson_status_locked.tr()), findsNWidgets(3));
  });

  testWidgets('course progress reflects completed lessons', (tester) async {
    await pumpAppWidget(
      tester,
      const CourseDetailsPage(courseId: courseId),
      overrides: overridesWith(completedFirst),
    );

    // 1 of 5 lessons done.
    expect(
      find.text(
        LocaleKeys.courses_progressPercent
            .tr(namedArgs: <String, String>{'percent': '20'}),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an unknown course id shows an error card, not a crash',
      (tester) async {
    await pumpAppWidget(
      tester,
      const CourseDetailsPage(courseId: 'does-not-exist'),
      overrides: overridesWith(const <String, LessonProgressModel>{}),
    );

    expect(find.text(LocaleKeys.errors_catalogueCorrupt.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
