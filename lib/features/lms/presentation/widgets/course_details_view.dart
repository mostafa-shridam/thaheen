import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/widgets/app_empty_view.dart';
import 'package:thaheen_task/core/widgets/app_snack_bar.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_details_header.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_resume_button.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_section_header.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/lesson_tile.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// The loaded state of the details screen: header, resume button, and every
/// section with its lessons.
///
/// Navigation is handed in as [onOpenLesson] so this widget stays independent
/// of the router and of the page that hosts it.
class CourseDetailsView extends ConsumerWidget {
  const CourseDetailsView({
    super.key,
    required this.course,
    required this.onOpenLesson,
  });

  final CourseModel course;
  final ValueChanged<String> onOpenLesson;

  /// Explains, in the student's language, why a locked lesson will not open.
  ///
  /// Naming the blocking lesson turns a dead end into an instruction — the
  /// student learns exactly what to finish next.
  void _explainLock(BuildContext context, String lessonId) {
    final blocking = course.blockingLessonFor(lessonId);
    final message = blocking == null
        ? LocaleKeys.lesson_lockedMessageGeneric.tr()
        : LocaleKeys.lesson_lockedMessage
            .tr(namedArgs: <String, String>{'title': blocking.title});

    AppSnackBar.show(
      context,
      message: message,
      icon: Icons.lock_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = AppBreakpoints.pagePadding(context);

    if (!course.hasLessons) {
      return const Center(
        child: AppEmptyView(
          messageKey: LocaleKeys.courseDetails_emptyCourse,
          hintKey: LocaleKeys.courseDetails_emptyCourseHint,
          icon: Icons.menu_book_outlined,
        ),
      );
    }

    // Running index across the whole course: the unlock rule is defined over
    // this flattened order, not over each section separately.
    var runningIndex = -1;

    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(padding, 8, padding, 28),
      children: <Widget>[
        CourseDetailsHeader(course: course),
        const SizedBox(height: 22),
        CourseResumeButton(course: course, onOpen: onOpenLesson),
        const SizedBox(height: 24),
        Text(
          LocaleKeys.courseDetails_contentTitle.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final section in course.sections) ...<Widget>[
          CourseSectionHeader(section: section),
          const SizedBox(height: 8),
          if (section.isEmpty)
            const AppEmptyView(
              messageKey: LocaleKeys.courseDetails_emptySection,
              compact: true,
            )
          else
            for (final lesson in section.lessons) ...<Widget>[
              Builder(
                builder: (context) {
                  final index = ++runningIndex;
                  return LessonTile(
                    course: course,
                    lesson: lesson,
                    index: index,
                    onTap: () => onOpenLesson(lesson.id),
                    onLockedTap: () => _explainLock(context, lesson.id),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
