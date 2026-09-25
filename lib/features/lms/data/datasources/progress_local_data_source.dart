import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:thaheen_task/core/storage/hive_boxes.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_progress_model.dart';

/// Reads and writes watch progress in Hive.
///
/// One `Box<String>` keyed by lesson id, each value a JSON blob. Reads are
/// synchronous because Hive keeps an open box in memory — which is what lets
/// the progress provider build without an `AsyncValue`, so a lesson list never
/// flashes a spinner just to learn which lessons are done.
///
/// Every method is safe when storage is unavailable: a closed box reads as
/// empty and swallows writes, so the app degrades to session-only progress
/// instead of failing.
class ProgressLocalDataSource {
  const ProgressLocalDataSource();

  /// Every saved record, keyed by lesson id.
  ///
  /// A row that fails to decode is skipped rather than throwing: one corrupt
  /// entry must not cost the student every other lesson's progress.
  ProgressByLesson readAll() {
    final box = HiveBoxes.lessonProgressBox;
    if (box == null) return const <String, LessonProgressModel>{};

    final result = <String, LessonProgressModel>{};
    for (final key in box.keys) {
      if (key is! String) continue;
      final decoded = _decode(box.get(key), key);
      if (decoded != null) result[key] = decoded;
    }
    return result;
  }

  LessonProgressModel readOne(String lessonId) =>
      _decode(HiveBoxes.lessonProgressBox?.get(lessonId), lessonId) ??
      LessonProgressModel.untouched(lessonId);

  Future<void> write(LessonProgressModel progress) async {
    await HiveBoxes.lessonProgressBox
        ?.put(progress.lessonId, jsonEncode(progress.toJson()));
  }

  /// Wipes all saved progress. Used by the "reset progress" action.
  Future<void> clear() async => HiveBoxes.lessonProgressBox?.clear();

  LessonProgressModel? _decode(String? raw, String fallbackLessonId) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return LessonProgressModel.fromJson(
        decoded,
        fallbackLessonId: fallbackLessonId,
      );
    } on FormatException catch (error) {
      debugPrint('Skipping unreadable progress row "$fallbackLessonId": $error');
      return null;
    }
  }
}
