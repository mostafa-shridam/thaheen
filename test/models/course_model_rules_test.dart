import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_progress_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_status.dart';
import 'package:thaheen_task/features/lms/data/models/section_model.dart';

/// Covers the sequential-unlock rule and the course progress calculation.
void main() {
  /// A course shaped like the real catalogue: two sections, 3 + 2 lessons,
  /// ids `l1`..`l5` in the order a student walks them.
  CourseModel buildCourse({List<int> lessonsPerSection = const <int>[3, 2]}) {
    var counter = 0;
    return CourseModel(
      id: 'c1',
      title: 'مقدمة في التشريح',
      instructor: 'د. سارة',
      thumbnail: 'assets/images/anatomy.png',
      sections: <SectionModel>[
        for (var s = 0; s < lessonsPerSection.length; s++)
          SectionModel(
            id: 's${s + 1}',
            title: 'قسم ${s + 1}',
            lessons: <LessonModel>[
              for (var i = 0; i < lessonsPerSection[s]; i++)
                LessonModel(
                  id: 'l${++counter}',
                  title: 'درس $counter',
                  durationSec: 100,
                  video: 'assets/videos/lesson_1.mp4',
                ),
            ],
          ),
      ],
    );
  }

  /// Progress where each listed lesson is completed.
  ProgressByLesson completed(List<String> lessonIds) => <String, LessonProgressModel>{
        for (final id in lessonIds)
          id: LessonProgressModel(
            lessonId: id,
            positionSec: 100,
            watchedSec: 100,
            durationSec: 100,
            completed: true,
          ),
      };

  /// Progress where a lesson is started but not finished.
  ProgressByLesson startedOnly(String lessonId, {int watched = 30}) =>
      <String, LessonProgressModel>{
        lessonId: LessonProgressModel(
          lessonId: lessonId,
          positionSec: watched,
          watchedSec: watched,
          durationSec: 100,
        ),
      };

  group('course structure', () {
    test('flattens lessons across sections in walking order', () {
      expect(
        buildCourse().orderedLessons.map((lesson) => lesson.id),
        <String>['l1', 'l2', 'l3', 'l4', 'l5'],
      );
    });

    test('a course of only empty sections has no lessons', () {
      final course = buildCourse(lessonsPerSection: const <int>[0, 0]);

      expect(course.hasLessons, isFalse);
      expect(course.lessonCount, 0);
    });
  });

  group('the sequential unlock rule', () {
    test('the first lesson is always open', () {
      // Otherwise a brand-new course could never be started.
      expect(
        buildCourse().isLessonUnlockedAt(0, const <String, LessonProgressModel>{}),
        isTrue,
      );
    });

    test('a later lesson is locked until the one before it is completed', () {
      final course = buildCourse();
      const none = <String, LessonProgressModel>{};

      expect(course.isLessonUnlocked('l2', none), isFalse);
      expect(course.isLessonUnlocked('l3', none), isFalse);
    });

    test('completing a lesson unlocks exactly the next one', () {
      final course = buildCourse();
      final progress = completed(<String>['l1']);

      expect(course.isLessonUnlocked('l2', progress), isTrue);
      expect(course.isLessonUnlocked('l3', progress), isFalse,
          reason: 'unlocking must not skip ahead');
    });

    test('merely starting a lesson does not unlock the next', () {
      final course = buildCourse();

      expect(course.isLessonUnlocked('l2', startedOnly('l1', watched: 89)), isFalse);
    });

    test('unlocking carries across a section boundary', () {
      // l3 ends section one, l4 opens section two.
      final course = buildCourse();

      expect(
        course.isLessonUnlocked('l4', completed(<String>['l1', 'l2', 'l3'])),
        isTrue,
      );
    });

    test('an unknown lesson id is locked rather than throwing', () {
      // A stale deep link becomes a friendly message, not a crash.
      final course = buildCourse();

      expect(course.isLessonUnlocked('nope', completed(<String>['l1'])), isFalse);
    });

    test('reports the lesson that is blocking a locked one', () {
      final course = buildCourse();

      expect(course.blockingLessonFor('l3')?.id, 'l2');
      expect(course.blockingLessonFor('l1'), isNull,
          reason: 'nothing blocks the opening lesson');
    });
  });

  group('lesson status', () {
    test('reads completed / inProgress / locked in one pass', () {
      final course = buildCourse();
      final progress = <String, LessonProgressModel>{
        ...completed(<String>['l1']),
        ...startedOnly('l2'),
      };

      expect(course.statusOf('l1', progress), LessonStatus.completed);
      expect(course.statusOf('l2', progress), LessonStatus.inProgress);
      // l2 is started but unfinished, so l3 is still shut.
      expect(course.statusOf('l3', progress), LessonStatus.locked);
    });

    test('an unlocked but untouched lesson reads notStarted', () {
      final course = buildCourse();
      final progress = completed(<String>['l1']);

      expect(course.statusOf('l2', progress), LessonStatus.notStarted);
    });

    test('a completed lesson never regresses to locked', () {
      // Completion outranks the unlock rule, so re-opening finished material
      // stays possible even if data around it changes.
      final course = buildCourse();

      expect(
        course.statusOf('l3', completed(<String>['l3'])),
        LessonStatus.completed,
      );
    });
  });

  group('the course progress calculation', () {
    test('an untouched course is 0%', () {
      expect(
        buildCourse().progressPercent(const <String, LessonProgressModel>{}),
        0,
      );
    });

    test('counts whole completed lessons only', () {
      final course = buildCourse(); // 5 lessons
      final progress = <String, LessonProgressModel>{
        ...completed(<String>['l1', 'l2']),
        ...startedOnly('l3', watched: 89),
      };

      // 2 of 5 done; the part-watched third has not crossed 90%.
      expect(course.progressPercent(progress), 40);
      expect(course.completedLessonCount(progress), 2);
    });

    test('a finished course is 100%', () {
      final course = buildCourse();
      final progress = completed(<String>['l1', 'l2', 'l3', 'l4', 'l5']);

      expect(course.progressPercent(progress), 100);
      expect(course.isCompleted(progress), isTrue);
    });

    test('rounds down so 100% never appears early', () {
      // 2 of 3 is 66.6…% — it must read 66, not 67.
      final course = buildCourse(lessonsPerSection: const <int>[3]);

      expect(course.progressPercent(completed(<String>['l1', 'l2'])), 66);
    });

    test('an empty course is 0% and never divides by zero', () {
      final course = buildCourse(lessonsPerSection: const <int>[0]);

      expect(course.progressRatio(const <String, LessonProgressModel>{}), 0);
      expect(course.progressPercent(const <String, LessonProgressModel>{}), 0);
      expect(course.isCompleted(const <String, LessonProgressModel>{}), isFalse);
    });
  });

  group('navigation helpers', () {
    test('lessonAfter walks across sections and stops at the end', () {
      final course = buildCourse();

      expect(course.lessonAfter('l3')?.id, 'l4');
      expect(course.lessonAfter('l5'), isNull);
    });

    test('resume points at the first unfinished unlocked lesson', () {
      final course = buildCourse();

      expect(
        course.resumeLesson(const <String, LessonProgressModel>{})?.id,
        'l1',
      );
      expect(
        course.resumeLesson(<String, LessonProgressModel>{
          ...completed(<String>['l1']),
          ...startedOnly('l2'),
        })?.id,
        'l2',
      );
    });

    test('resume is null once the course is finished', () {
      final course = buildCourse();

      expect(
        course.resumeLesson(completed(<String>['l1', 'l2', 'l3', 'l4', 'l5'])),
        isNull,
      );
    });
  });
}
