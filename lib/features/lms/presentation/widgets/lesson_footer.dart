import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_model.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Everything below the video: the next-lesson call to action.
///
/// Navigation is handed in as [onOpenNext] so the unlock decision and the
/// route stay in separate places.
class LessonFooter extends ConsumerWidget {
  const LessonFooter({
    super.key,
    required this.course,
    required this.lesson,
    required this.onOpenNext,
  });

  final CourseModel course;
  final LessonModel lesson;
  final ValueChanged<LessonModel> onOpenNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(progressControllerProvider);
    final next = course.lessonAfter(lesson.id);

    if (next == null) {
      return _FooterNote(
        icon: Icons.flag_outlined,
        text: course.isCompleted(progress)
            ? LocaleKeys.lesson_courseFinished.tr()
            : LocaleKeys.lesson_isLastLesson.tr(),
      );
    }

    final unlocked = course.isLessonUnlocked(next.id, progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(lesson.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        FilledButton.icon(
          // Shown disabled rather than hidden: the student can see what comes
          // next and what it will take to get there.
          onPressed: unlocked ? () => onOpenNext(next) : null,
          icon: Icon(unlocked ? Icons.skip_next_rounded : Icons.lock_outline_rounded),
          label: Text(LocaleKeys.lesson_next.tr()),
        ),
        const SizedBox(height: 8),
        Text(
          unlocked ? next.title : LocaleKeys.lesson_nextLocked.tr(),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// A single muted line with a leading icon. Private: it is a leaf of this
/// component and has no meaning outside it.
class _FooterNote extends StatelessWidget {
  const _FooterNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: theme.palette.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}
