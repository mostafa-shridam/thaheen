import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_task/core/storage/hive_boxes.dart';
import 'package:thaheen_task/features/lms/data/datasources/progress_local_data_source.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_progress_model.dart';

/// Exercises persistence against a real Hive box on disk, including the
/// restart the task explicitly asks about: progress must survive the app being
/// closed and reopened.
void main() {
  const source = ProgressLocalDataSource();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('thaheen_hive_test');
    await HiveBoxes.initAt(tempDir.path);
    await HiveBoxes.clear();
  });

  tearDown(() async {
    await HiveBoxes.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('an empty store reads as no progress', () {
    expect(source.readAll(), isEmpty);
    expect(source.readOne('l1'), const LessonProgressModel.untouched('l1'));
  });

  test('a written record reads back identically', () async {
    const progress = LessonProgressModel(
      lessonId: 'l1',
      positionSec: 42,
      watchedSec: 55,
      durationSec: 100,
      updatedAtMs: 1700000000000,
    );

    await source.write(progress);

    expect(source.readOne('l1'), progress);
    expect(source.readAll(), <String, LessonProgressModel>{'l1': progress});
  });

  test('progress survives closing and reopening the box', () async {
    // This is the "survives an app restart" requirement, end to end.
    await source.write(
      const LessonProgressModel(
        lessonId: 'l2',
        positionSec: 12,
        watchedSec: 95,
        durationSec: 100,
        completed: true,
      ),
    );

    await HiveBoxes.close();
    await HiveBoxes.initAt(tempDir.path);

    final restored = source.readOne('l2');
    expect(restored.completed, isTrue);
    expect(restored.positionSec, 12);
    expect(restored.watchedSec, 95);
  });

  test('writing the same lesson twice overwrites rather than duplicates', () async {
    await source.write(const LessonProgressModel(lessonId: 'l1', positionSec: 10));
    await source.write(const LessonProgressModel(lessonId: 'l1', positionSec: 30));

    expect(source.readAll(), hasLength(1));
    expect(source.readOne('l1').positionSec, 30);
  });

  test('a corrupt row is skipped, not fatal', () async {
    // One unreadable entry must not cost the student every other lesson.
    await source.write(const LessonProgressModel(lessonId: 'good', positionSec: 5));
    await HiveBoxes.lessonProgressBox!.put('bad', '{ not json');

    final all = source.readAll();

    expect(all.keys, <String>['good']);
    expect(source.readOne('bad'), const LessonProgressModel.untouched('bad'));
  });

  test('a row missing its lessonId recovers the id from its key', () async {
    await HiveBoxes.lessonProgressBox!
        .put('l7', jsonEncode(<String, dynamic>{'positionSec': 9}));

    expect(source.readOne('l7').lessonId, 'l7');
    expect(source.readAll()['l7']?.positionSec, 9);
  });

  test('clear wipes everything', () async {
    await source.write(const LessonProgressModel(lessonId: 'l1', positionSec: 10));
    await source.clear();

    expect(source.readAll(), isEmpty);
  });

  test('reads and writes are silently inert when storage is unavailable', () async {
    await HiveBoxes.close();

    // No throw, no crash — the app just runs without persistence.
    expect(source.readAll(), isEmpty);
    expect(source.readOne('l1'), const LessonProgressModel.untouched('l1'));
    await expectLater(
      source.write(const LessonProgressModel(lessonId: 'l1')),
      completes,
    );
  });
}
