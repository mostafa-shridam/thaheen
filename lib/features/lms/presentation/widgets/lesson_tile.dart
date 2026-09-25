import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';
import 'package:thaheen_task/core/utils/duration_format.dart';
import 'package:thaheen_task/core/widgets/app_container.dart';
import 'package:thaheen_task/core/widgets/app_progress_bar.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_progress_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_status.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// One lesson row: status badge, title, duration and a resume bar.
///
/// Watches only *this* lesson's status via `.select()`, so completing a lesson
/// repaints two rows — the one that finished and the one it just unlocked —
/// rather than the entire course.
class LessonTile extends ConsumerWidget {
  const LessonTile({
    super.key,
    required this.course,
    required this.lesson,
    required this.index,
    this.onTap,
    this.onLockedTap,
  });

  final CourseModel course;
  final LessonModel lesson;

  /// Position within `course.orderedLessons` — the ordering the unlock rule
  /// is defined over, and the number shown on the badge.
  final int index;

  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      progressControllerProvider.select(
        (progress) => course.statusOfAt(index, progress),
      ),
    );
final isRtl = Directionality.of(context) == TextDirection.rtl;
    final theme = Theme.of(context);
    final palette = theme.palette;
    final isLocked = status.isLocked;

    return AppContainer(
      padding: const EdgeInsetsDirectional.all(12),
      // A locked tile still takes taps: it owes the student an explanation,
      // not silence.
      onTap: isLocked ? onLockedTap : onTap,
      child: Row(
        children: <Widget>[
          _StatusBadge(status: status, number: index + 1),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  lesson.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isLocked ? palette.locked : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _MetaLine(lesson: lesson, status: status),
                if (status == LessonStatus.inProgress) ...<Widget>[
                  const SizedBox(height: 8),
                  _ResumeBar(lesson: lesson),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            isLocked ? Icons.lock_outline_rounded : (isRtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
            size: isLocked ? 18 : 22,
            color: isLocked ? palette.locked : palette.textSecondary,
          ),
        ],
      ),
    );
  }
}

/// Circular leading badge: a number, a tick, a lock or a play glyph.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.number});

  final LessonStatus status;
  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;

    final (Color background, Color foreground) = switch (status) {
      LessonStatus.completed => (
          palette.success.withValues(alpha: 0.12),
          palette.success,
        ),
      LessonStatus.inProgress => (
          theme.colorScheme.primary.withValues(alpha: 0.12),
          theme.colorScheme.primary,
        ),
      LessonStatus.notStarted => (palette.border, palette.textSecondary),
      LessonStatus.locked => (
          palette.border.withValues(alpha: 0.6),
          palette.locked,
        ),
    };

    return AppContainer(
      shape: AppSurfaceShape.circle,
      color: background,
      width: 38,
      height: 38,
      alignment: Alignment.center,
      child: switch (status) {
        LessonStatus.completed =>
          Icon(Icons.check_rounded, size: 20, color: foreground),
        LessonStatus.locked =>
          Icon(Icons.lock_rounded, size: 17, color: foreground),
        LessonStatus.inProgress =>
          Icon(Icons.play_arrow_rounded, size: 21, color: foreground),
        LessonStatus.notStarted => Text(
            '$number',
            style: theme.textTheme.labelMedium?.copyWith(color: foreground),
          ),
      },
    );
  }
}

/// Duration plus the localised status word.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.lesson, required this.status});

  final LessonModel lesson;
  final LessonStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;

    final statusKey = switch (status) {
      LessonStatus.locked => LocaleKeys.lesson_status_locked,
      LessonStatus.notStarted => LocaleKeys.lesson_status_notStarted,
      LessonStatus.inProgress => LocaleKeys.lesson_status_inProgress,
      LessonStatus.completed => LocaleKeys.lesson_status_completed,
    };

    final statusColor = switch (status) {
      LessonStatus.completed => palette.success,
      LessonStatus.inProgress => theme.colorScheme.primary,
      _ => palette.textSecondary,
    };

    return Row(
      children: <Widget>[
        Icon(Icons.schedule_rounded, size: 13, color: palette.textSecondary),
        const SizedBox(width: 4),
        Text(
          formatClockFromSeconds(lesson.durationSec),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(width: 8),
        Text('·', style: theme.textTheme.bodySmall),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            statusKey.tr(),
            style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Thin bar showing how far into a part-watched lesson the student got.
class _ResumeBar extends ConsumerWidget {
  const _ResumeBar({required this.lesson});

  final LessonModel lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = ref.watch(
      progressControllerProvider.select(
        (progress) =>
            progress.forLesson(lesson.id).watchedRatio(lesson.durationSec),
      ),
    );

    return AppProgressBar(value: ratio, height: 4);
  }
}
