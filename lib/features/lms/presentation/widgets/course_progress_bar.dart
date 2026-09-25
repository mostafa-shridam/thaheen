import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';
import 'package:thaheen_task/core/widgets/app_progress_bar.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Completion bar and percentage for one course.
///
/// Watches progress through `.select()` so this widget — and only this widget —
/// rebuilds when *its* course's percentage changes. Finishing a lesson in one
/// course leaves every other card in the list untouched.
class CourseProgressBar extends ConsumerWidget {
  const CourseProgressBar({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = ref.watch(
      progressControllerProvider.select(course.progressPercent),
    );

    final theme = Theme.of(context);
    final palette = theme.palette;
    final isComplete = percent >= 100;
    final accent = isComplete ? palette.success : theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (isComplete) ...<Widget>[
              Icon(Icons.verified_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                isComplete
                    ? LocaleKeys.courses_completedCourse.tr()
                    : percent == 0
                        ? LocaleKeys.courses_notStartedYet.tr()
                        : LocaleKeys.courses_progressPercent
                            .tr(namedArgs: <String, String>{'percent': '$percent'}),
                style: theme.textTheme.labelMedium?.copyWith(color: accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppProgressBar(
          // `/ 100` rather than the raw ratio so the bar and the label can
          // never disagree — both read the same rounded-down number.
          value: percent / 100,
          color: accent,
        ),
      ],
    );
  }
}
