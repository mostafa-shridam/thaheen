import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_progress_model.dart';

/// Covers the 90% auto-completion rule and the resume/high-water-mark split.
void main() {
  const declared = 100;

  LessonProgressModel tick(
    LessonProgressModel from, {
    required int position,
    int reportedDuration = declared,
  }) =>
      from.afterPlayback(
        positionSec: position,
        reportedDurationSec: reportedDuration,
        declaredDurationSec: declared,
        now: DateTime.fromMillisecondsSinceEpoch(0),
      );

  group('the 90% completion rule', () {
    test('does not complete just below the threshold', () {
      final progress = tick(
        const LessonProgressModel.untouched('l1'),
        position: 89,
      );

      expect(progress.meetsCompletionThreshold(declared), isFalse);
      expect(progress.completed, isFalse);
    });

    test('completes exactly at the threshold', () {
      // 90/100 == 0.9, and the rule is `>=`, so this is the first completing tick.
      final progress = tick(
        const LessonProgressModel.untouched('l1'),
        position: 90,
      );

      expect(progress.meetsCompletionThreshold(declared), isTrue);
      expect(progress.completed, isTrue);
    });

    test('completes above the threshold', () {
      final progress = tick(
        const LessonProgressModel.untouched('l1'),
        position: 97,
      );

      expect(progress.completed, isTrue);
    });

    test('is measured against watched, not the live playhead', () {
      final finished = tick(
        const LessonProgressModel.untouched('l1'),
        position: 95,
      );
      // The student scrubs back to rewatch the tricky part.
      final rewound = tick(finished, position: 10);

      expect(rewound.positionSec, 10, reason: 'resume point follows the playhead');
      expect(rewound.watchedSec, 95, reason: 'watched is a high-water mark');
      expect(rewound.completed, isTrue, reason: 'completion never un-latches');
    });

    test('cannot complete while the duration is unknown', () {
      // Guessing completion off a zero duration would mark lesson one done the
      // instant a corrupt video fails to report its length.
      final progress = const LessonProgressModel.untouched('l1').afterPlayback(
        positionSec: 500,
        reportedDurationSec: 0,
        declaredDurationSec: 0,
      );

      expect(progress.meetsCompletionThreshold(0), isFalse);
      expect(progress.completed, isFalse);
    });

    test('falls back to the declared duration until the player reports one', () {
      final progress = const LessonProgressModel.untouched('l1').afterPlayback(
        positionSec: 95,
        reportedDurationSec: 0,
        declaredDurationSec: declared,
      );

      expect(progress.completed, isTrue);
    });

    test('prefers the player duration over a wrong declared one', () {
      // Catalogue claims 100s, the real file is 200s: 95s is only 47%.
      final progress = const LessonProgressModel.untouched('l1').afterPlayback(
        positionSec: 95,
        reportedDurationSec: 200,
        declaredDurationSec: declared,
      );

      expect(progress.durationSec, 200);
      expect(progress.completed, isFalse);
    });
  });

  group('watchedRatio', () {
    test('is zero for an untouched lesson', () {
      expect(
        const LessonProgressModel.untouched('l1').watchedRatio(declared),
        0,
      );
    });

    test('is a full 1.0 once completed, even with a stale duration', () {
      const progress = LessonProgressModel(
        lessonId: 'l1',
        watchedSec: 5,
        durationSec: 900,
        completed: true,
      );

      expect(progress.watchedRatio(declared), 1);
    });

    test('never exceeds 1.0 when the playhead overshoots', () {
      const progress = LessonProgressModel(
        lessonId: 'l1',
        watchedSec: 140,
        durationSec: declared,
      );

      expect(progress.watchedRatio(declared), 1);
    });
  });

  group('persistence round-trip', () {
    test('survives toJson -> fromJson unchanged', () {
      final original = tick(
        const LessonProgressModel.untouched('l1'),
        position: 42,
      );

      final restored = LessonProgressModel.fromJson(
        original.toJson(),
        fallbackLessonId: 'l1',
      );

      expect(restored, original);
    });

    test('recovers a payload that lost its lesson id', () {
      final restored = LessonProgressModel.fromJson(
        <String, dynamic>{'positionSec': 12, 'watchedSec': 12},
        fallbackLessonId: 'l9',
      );

      expect(restored.lessonId, 'l9');
      expect(restored.positionSec, 12);
    });

    test('tolerates a payload with unknown and missing keys', () {
      final restored = LessonProgressModel.fromJson(
        <String, dynamic>{'lessonId': 'l1', 'somethingNew': true},
        fallbackLessonId: 'l1',
      );

      expect(restored, const LessonProgressModel.untouched('l1'));
    });
  });
}
