import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// The primary call to action: start, continue, or review a finished course.
class CourseResumeButton extends ConsumerWidget {
  const CourseResumeButton({super.key, required this.course, required this.onOpen});

  final CourseModel course;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider);
    final resume = course.resumeLesson(progress);
    final started = course.completedLessonCount(progress) > 0;

    // A finished course has no resume target, so fall back to its first lesson
    // for a rewatch rather than disabling the button.
    final target = resume ?? course.orderedLessons.firstOrNull;
    if (target == null) return const SizedBox.shrink();

    final labelKey = resume == null
        ? LocaleKeys.courseDetails_reviewCourse
        : started
            ? LocaleKeys.courseDetails_continueCourse
            : LocaleKeys.courseDetails_startCourse;

    return FilledButton.icon(
      onPressed: () => onOpen(target.id),
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text(labelKey.tr()),
    );
  }
}
