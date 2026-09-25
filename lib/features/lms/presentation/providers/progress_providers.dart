import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:thaheen_task/features/lms/data/datasources/progress_local_data_source.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_progress_model.dart';
import 'package:thaheen_task/features/lms/presentation/providers/catalogue_providers.dart';

part 'progress_providers.g.dart';

@Riverpod(keepAlive: true)
ProgressLocalDataSource progressLocalDataSource(Ref ref) =>
    const ProgressLocalDataSource();

/// The student's progress across every lesson, held in memory and mirrored to Hive.
///
/// Built synchronously from an already-open Hive box, so consumers get a plain
/// `Map` rather than an `AsyncValue` — a lesson list never flashes a spinner
/// just to find out which lessons are done.
///
/// **State is live; persistence is debounced.** These are two different
/// concerns and conflating them was a bug: when the Hive write was the only
/// thing that advanced state, a lesson's progress bar and the next-lesson
/// button did not move until the student left the player and came back.
///
/// So [record] updates `state` on *every* call — the lesson tile, the course
/// progress bar and the unlock rule all follow the playhead in real time —
/// while the write to disk is coalesced behind [_persistDebounce]. Completion
/// is the exception and is written through immediately, because it drives the
/// unlock rule and must survive a force-kill the instant it happens.
///
/// [record] is the single write path. Widgets never touch the data source.
@Riverpod(keepAlive: true)
class ProgressController extends _$ProgressController {
  /// How long an in-progress position may sit in memory before it is written.
  ///
  /// Writing on every tick would hammer storage; writing only on exit would
  /// lose the session to a force-kill. Five seconds keeps the worst-case loss
  /// small and the write rate trivial.
  static const Duration _persistDebounce = Duration(seconds: 5);

  Timer? _persistTimer;

  /// Records advanced in memory but not yet on disk, keyed by lesson id.
  final Map<String, LessonProgressModel> _unsaved =
      <String, LessonProgressModel>{};

  @override
  ProgressByLesson build() {
    ref.onDispose(_cancelTimer);
    return ref.watch(progressLocalDataSourceProvider).readAll();
  }

  /// Folds one playback tick into state, and schedules it for storage.
  ///
  /// Returns `true` when this tick *completed* the lesson, so the player can
  /// celebrate exactly once instead of on every subsequent tick.
  ///
  /// A tick that changes nothing — the same second reported twice — leaves
  /// `state` identical, so `.select()` watchers do not rebuild.
  Future<bool> record({
    required String lessonId,
    required int positionSec,
    required int reportedDurationSec,
    required int declaredDurationSec,
  }) async {
    final current = state.forLesson(lessonId);
    final next = current.afterPlayback(
      positionSec: positionSec,
      reportedDurationSec: reportedDurationSec,
      declaredDurationSec: declaredDurationSec,
    );

    // `updatedAt` always moves, so compare the fields that actually matter.
    final unchanged = next.positionSec == current.positionSec &&
        next.watchedSec == current.watchedSec &&
        next.durationSec == current.durationSec &&
        next.completed == current.completed;
    if (unchanged) return false;

    // Live, always — this is what every watcher is rebuilt from.
    state = <String, LessonProgressModel>{...state, lessonId: next};
    _unsaved[lessonId] = next;

    final justCompleted = next.completed && !current.completed;
    if (justCompleted) {
      // Never leave a completion sitting in memory: it unlocks the next lesson.
      await flush();
    } else {
      _schedulePersist();
    }

    return justCompleted;
  }

  void _schedulePersist() {
    _persistTimer ??= Timer(_persistDebounce, () {
      _persistTimer = null;
      unawaited(flush());
    });
  }

  /// Writes everything held in memory.
  ///
  /// Called on pause, on leaving a lesson and when the app is backgrounded —
  /// every moment where the next thing to happen might be the process dying.
  Future<void> flush() async {
    _cancelTimer();
    if (_unsaved.isEmpty) return;

    final pending = List<LessonProgressModel>.of(_unsaved.values);
    _unsaved.clear();

    final source = ref.read(progressLocalDataSourceProvider);
    for (final progress in pending) {
      await source.write(progress);
    }
  }

  /// Clears every saved position and completion flag.
  Future<void> resetAll() async {
    _cancelTimer();
    _unsaved.clear();
    await ref.read(progressLocalDataSourceProvider).clear();
    state = const <String, LessonProgressModel>{};
  }

  void _cancelTimer() {
    _persistTimer?.cancel();
    _persistTimer = null;
  }
}

/// Where the "continue watching" card should send the student.
class ResumeTarget {
  const ResumeTarget({
    required this.course,
    required this.lesson,
    required this.progress,
  });

  final CourseModel course;
  final LessonModel lesson;
  final LessonProgressModel progress;

  /// How far into the lesson the student stopped, in `0.0..1.0`.
  double get watchedRatio => progress.watchedRatio(lesson.durationSec);
}

/// The lesson the student was last watching and has not finished.
///
/// "Last" is decided by `updatedAt`, not by catalogue order, so the card always
/// points at what the student actually touched most recently — even if that was
/// lesson 2 of the second course. Returns `null` when nothing is part-watched,
/// which is what hides the card on a fresh install.
@riverpod
Future<ResumeTarget?> continueWatching(Ref ref) async {
  final courses = await ref.watch(courseCatalogueProvider.future);
  final progress = ref.watch(progressControllerProvider);

  ResumeTarget? best;
  var bestAt = DateTime.fromMillisecondsSinceEpoch(0);

  for (final course in courses) {
    for (final lesson in course.orderedLessons) {
      final saved = progress.forLesson(lesson.id);
      if (saved.completed || !saved.hasStarted) continue;

      final touchedAt = saved.updatedAt;
      if (touchedAt == null || !touchedAt.isAfter(bestAt)) continue;

      bestAt = touchedAt;
      best = ResumeTarget(course: course, lesson: lesson, progress: saved);
    }
  }

  return best;
}
