import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thaheen_task/core/error/failures.dart';
import 'package:thaheen_task/core/widgets/app_error_view.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/presentation/providers/catalogue_providers.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/lesson_locked_notice.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/lesson_player_shell.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/lesson_player_view.dart';

/// Plays one lesson.
///
/// This screen only resolves state: it finds the course, finds the lesson, and
/// checks the unlock rule. Each outcome is a widget of its own, so the player
/// itself is built against concrete, non-null data and the video controller is
/// created exactly once, in a widget that already knows which asset it plays.
class LessonPlayerPage extends ConsumerWidget {
  const LessonPlayerPage({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  static const String routeName = 'lesson-player';

  /// Declared relative to [CourseDetailsPage]'s route.
  static const String routePath = 'lessons/:lessonId';
  static const String lessonIdParam = 'lessonId';

  final String courseId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseByIdProvider(courseId));

    switch (course) {
      case AsyncError(:final error):
        return LessonPlayerShell(
          child: AppErrorView.fromError(
            error,
            onRetry: () => ref.invalidate(courseByIdProvider(courseId)),
          ),
        );

      case AsyncData(value: final CourseModel loaded):
        final lesson = loaded.lessonById(lessonId);
        if (lesson == null) {
          return const LessonPlayerShell(
            child: AppErrorView(
              failure: AppFailure(
                FailureCode.catalogueCorrupt,
                debugDetail: 'lesson id not in course',
              ),
            ),
          );
        }

        // A deep link into a still-locked lesson is refused here rather than in
        // the router, so the student gets the same explanation the lesson list
        // gives.
        final progress = ref.watch(progressControllerProvider);
        if (!loaded.isLessonUnlocked(lesson.id, progress)) {
          return LessonPlayerShell(
            title: lesson.title,
            child: LessonLockedNotice(course: loaded, lesson: lesson),
          );
        }

        return LessonPlayerView(course: loaded, lesson: lesson);

      case _:
        return const LessonPlayerShell(
          child: Center(child: CircularProgressIndicator()),
        );
    }
  }
}
