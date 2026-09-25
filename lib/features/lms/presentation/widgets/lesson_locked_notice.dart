import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_model.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Shown when a lesson is reached before the one that unlocks it.
///
/// Names the blocking lesson so the dead end reads as an instruction.
class LessonLockedNotice extends StatelessWidget {
  const LessonLockedNotice({super.key, required this.course, required this.lesson});

  final CourseModel course;
  final LessonModel lesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocking = course.blockingLessonFor(lesson.id);

    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.lock_outline_rounded, size: 40, color: theme.palette.locked),
            const SizedBox(height: 14),
            Text(
              LocaleKeys.lesson_lockedTitle.tr(),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              blocking == null
                  ? LocaleKeys.lesson_lockedMessageGeneric.tr()
                  : LocaleKeys.lesson_lockedMessage
                      .tr(namedArgs: <String, String>{'title': blocking.title}),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
