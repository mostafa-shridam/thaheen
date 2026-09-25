import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_task/core/error/failures.dart';
import 'package:thaheen_task/features/lms/data/datasources/course_asset_data_source.dart';

import '../fixtures/fake_asset_bundle.dart';
import '../fixtures/mp4_duration.dart';

void main() {
  const path = CourseAssetDataSource.assetPath;

  CourseAssetDataSource sourceWith(String? catalogue) => CourseAssetDataSource(
        bundle: FakeAssetBundle(<String, String>{
          path: ?catalogue,
        }),
      );

  group('the real bundled catalogue', () {
    late String realCatalogue;

    setUpAll(() {
      realCatalogue = File(path).readAsStringSync();
    });

    test('parses into the shape the task asks for', () async {
      final courses =
          await sourceWith(realCatalogue).readCourses();

      expect(courses, hasLength(2));
      for (final course in courses) {
        expect(course.sections, hasLength(2), reason: '${course.id} sections');
        expect(course.hasLessons, isTrue);
        for (final section in course.sections) {
          expect(
            section.lessons.length,
            inInclusiveRange(2, 3),
            reason: '${section.id} lesson count',
          );
        }
      }
    });

    test('every referenced asset actually exists on disk', () async {
      final courses =
          await sourceWith(realCatalogue).readCourses();

      for (final course in courses) {
        expect(
          File(course.thumbnail).existsSync(),
          isTrue,
          reason: 'missing thumbnail ${course.thumbnail}',
        );
        for (final lesson in course.orderedLessons) {
          expect(
            File(lesson.video).existsSync(),
            isTrue,
            reason: 'missing video ${lesson.video}',
          );
        }
      }
    });

    test('declared durations match the real video files', () async {
      // `durationSec` is shown to students before a video loads, so it must not
      // drift from the bundled file. One second of slack covers rounding.
      final courses = await sourceWith(realCatalogue).readCourses();

      for (final course in courses) {
        for (final lesson in course.orderedLessons) {
          final actual = readMp4Duration(File(lesson.video));
          expect(actual, isNotNull, reason: 'unreadable ${lesson.video}');
          expect(
            (actual!.inSeconds - lesson.durationSec).abs(),
            lessThanOrEqualTo(1),
            reason: '${lesson.id} declares ${lesson.durationSec}s but '
                '${lesson.video} is ${actual.inSeconds}s',
          );
        }
      }
    });

    test('every lesson is long enough to demonstrate the 90% rule', () async {
      final courses = await sourceWith(realCatalogue).readCourses();

      for (final course in courses) {
        for (final lesson in course.orderedLessons) {
          expect(
            lesson.durationSec,
            greaterThanOrEqualTo(50),
            reason: '${lesson.id} is too short to watch meaningfully',
          );
        }
      }
    });

    test('every video is under the 10 MB budget', () async {
      final courses = await sourceWith(realCatalogue).readCourses();

      for (final course in courses) {
        for (final lesson in course.orderedLessons) {
          final megabytes = File(lesson.video).lengthSync() / (1024 * 1024);
          expect(megabytes, lessThan(10), reason: lesson.video);
        }
      }
    });

    test('lesson ids are unique across the whole catalogue', () async {
      final courses =
          await sourceWith(realCatalogue).readCourses();

      // Progress is persisted under the lesson id, so a collision would make
      // two different lessons share one watch position.
      final ids = [
        for (final course in courses)
          for (final lesson in course.orderedLessons) lesson.id,
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('failure handling', () {
    test('a missing catalogue reports catalogueMissing', () {
      expect(
        () => sourceWith(null).readCourses(),
        throwsA(
          isA<AppFailure>()
              .having((f) => f.code, 'code', FailureCode.catalogueMissing),
        ),
      );
    });

    test('unparseable JSON reports catalogueCorrupt', () {
      expect(
        () => sourceWith('{ not json ').readCourses(),
        throwsA(
          isA<AppFailure>()
              .having((f) => f.code, 'code', FailureCode.catalogueCorrupt),
        ),
      );
    });

    test('a lesson missing its id reports catalogueCorrupt', () {
      const catalogue = '''
{"courses":[{"id":"c","title":"t","instructor":"i","thumbnail":"a.png",
 "sections":[{"id":"s","title":"s","lessons":[{"title":"no id"}]}]}]}''';

      expect(
        () => sourceWith(catalogue).readCourses(),
        throwsA(
          isA<AppFailure>()
              .having((f) => f.code, 'code', FailureCode.catalogueCorrupt),
        ),
      );
    });
  });

  group('tolerated gaps', () {
    test('a section with no lessons parses as an empty section', () async {
      const catalogue = '''
{"courses":[{"id":"c","title":"دورة","instructor":"د. أحمد","thumbnail":"a.png",
 "sections":[{"id":"s","title":"قسم فارغ"}]}]}''';

      final courses =
          await sourceWith(catalogue).readCourses();

      expect(courses.single.sections.single.isEmpty, isTrue);
      expect(courses.single.hasLessons, isFalse);
      expect(courses.single.lessonCount, 0);
    });

    test('a lesson with no declared duration falls back to zero', () async {
      const catalogue = '''
{"courses":[{"id":"c","title":"دورة","instructor":"د. أحمد","thumbnail":"a.png",
 "sections":[{"id":"s","title":"قسم","lessons":[
   {"id":"l1","title":"درس","video":"v.mp4"}]}]}]}''';

      final courses =
          await sourceWith(catalogue).readCourses();

      // Survivable: the player reports the real duration once it initialises.
      expect(courses.single.orderedLessons.single.durationSec, 0);
    });
  });
}
