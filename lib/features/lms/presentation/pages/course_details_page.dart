import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:thaheen_task/core/error/failures.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/theme/app_theme.dart';
import 'package:thaheen_task/core/widgets/app_container.dart';
import 'package:thaheen_task/core/widgets/app_empty_view.dart';
import 'package:thaheen_task/core/widgets/app_error_view.dart';
import 'package:thaheen_task/core/widgets/app_skeleton_box.dart';
import 'package:thaheen_task/core/widgets/app_snack_bar.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/data/models/section_model.dart';
import 'package:thaheen_task/features/lms/presentation/pages/lesson_player_page.dart';
import 'package:thaheen_task/features/lms/presentation/providers/catalogue_providers.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_progress_bar.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_thumbnail.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/instructor_line.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/lesson_tile.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// A course's sections and lessons, with each lesson's status and lock state.
class CourseDetailsPage extends ConsumerWidget {
  const CourseDetailsPage({super.key, required this.courseId});

  static const String routeName = 'course-details';

  /// Declared relative to [CoursesPage]'s route.
  static const String routePath = 'courses/:courseId';
  static const String courseIdParam = 'courseId';

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseByIdProvider(courseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (course) {
            AsyncData(value: final CourseModel loaded) => loaded.title,
            _ => LocaleKeys.courseDetails_contentTitle.tr(),
          },
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMaxWidth,
            ),
            child: switch (course) {
              // An id that is not in the catalogue is a genuine miss, not a
              // crash: show the same calm card everything else uses.
              AsyncData(value: null) => const AppErrorView(
                  failure: AppFailure(
                    FailureCode.catalogueCorrupt,
                    debugDetail: 'course id not found',
                  ),
                ),
              AsyncData(value: final CourseModel loaded) => _Loaded(course: loaded),
              AsyncError(:final error) => AppErrorView.fromError(
                  error,
                  onRetry: () => ref.invalidate(courseByIdProvider(courseId)),
                ),
              _ => const _DetailsSkeleton(),
            },
          ),
        ),
      ),
    );
  }
}

double _pagePadding(BuildContext context) => ResponsiveValue<double>(
      context,
      defaultValue: 16,
      conditionalValues: const <Condition<double>>[
        Condition<double>.largerThan(name: MOBILE, value: 24),
      ],
    ).value;

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.course});

  final CourseModel course;

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

  void _openLesson(BuildContext context, String lessonId) =>
      context.pushNamed(LessonPlayerPage.routeName, pathParameters: <String, String>{
        CourseDetailsPage.courseIdParam: course.id,
        LessonPlayerPage.lessonIdParam: lessonId,
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = _pagePadding(context);

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
        _Header(course: course),
        const SizedBox(height: 22),
        _ResumeButton(
          course: course,
          onOpen: (lessonId) => _openLesson(context, lessonId),
        ),
        const SizedBox(height: 24),
        Text(
          LocaleKeys.courseDetails_contentTitle.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final section in course.sections) ...<Widget>[
          _SectionHeader(section: section),
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
                    onTap: () => _openLesson(context, lesson.id),
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

class _Header extends StatelessWidget {
  const _Header({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: CourseThumbnail(assetPath: course.thumbnail),
        ),
        const SizedBox(height: 16),
        Text(course.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        InstructorLine(
          name: course.instructor,
          trailing: Text(
            LocaleKeys.courses_lessonCount.plural(course.lessonCount),
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 16),
        CourseProgressBar(course: course),
      ],
    );
  }
}

/// The primary call to action: start, continue, or review a finished course.
class _ResumeButton extends ConsumerWidget {
  const _ResumeButton({required this.course, required this.onOpen});

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});

  final SectionModel section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 8, bottom: 2),
      child: Row(
        children: <Widget>[
          AppContainer(
            shape: AppSurfaceShape.pill,
            color: theme.colorScheme.primary,
            width: 4,
            height: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(section.title, style: theme.textTheme.titleMedium),
          ),
          Text(
            LocaleKeys.courses_lessonCount.plural(section.lessons.length),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    final padding = _pagePadding(context);
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(padding, 8, padding, 24),
      children: const <Widget>[
        AspectRatio(
          aspectRatio: 16 / 9,
          child: AppSkeletonBox(height: double.infinity, radius: 12),
        ),
        SizedBox(height: 16),
        AppSkeletonBox(width: 240, height: 20),
        SizedBox(height: 10),
        AppSkeletonBox(width: 150, height: 12),
        SizedBox(height: 20),
        AppSkeletonBox(height: 48, radius: 10),
        SizedBox(height: 28),
        AppSkeletonBox(width: 120),
        SizedBox(height: 16),
        AppSkeletonBox(height: 62, radius: 12),
        SizedBox(height: 8),
        AppSkeletonBox(height: 62, radius: 12),
        SizedBox(height: 8),
        AppSkeletonBox(height: 62, radius: 12),
      ],
    );
  }
}
