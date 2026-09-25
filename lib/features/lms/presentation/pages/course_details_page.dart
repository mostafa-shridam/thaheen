import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thaheen_task/core/error/failures.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/widgets/app_error_view.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/presentation/pages/lesson_player_page.dart';
import 'package:thaheen_task/features/lms/presentation/providers/catalogue_providers.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_details_skeleton.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_details_view.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// A course's sections and lessons, with each lesson's status and lock state.
///
/// The screen resolves the course and owns navigation; the loaded layout and
/// its parts live in their own widget files under `presentation/widgets/`.
class CourseDetailsPage extends ConsumerWidget {
  const CourseDetailsPage({super.key, required this.courseId});

  static const String routeName = 'course-details';

  /// Declared relative to [CoursesPage]'s route.
  static const String routePath = 'courses/:courseId';
  static const String courseIdParam = 'courseId';

  final String courseId;

  void _openLesson(BuildContext context, String lessonId) =>
      context.pushNamed(LessonPlayerPage.routeName, pathParameters: <String, String>{
        courseIdParam: courseId,
        LessonPlayerPage.lessonIdParam: lessonId,
      });

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
              AsyncData(value: final CourseModel loaded) => CourseDetailsView(
                  course: loaded,
                  onOpenLesson: (lessonId) => _openLesson(context, lessonId),
                ),
              AsyncError(:final error) => AppErrorView.fromError(
                  error,
                  onRetry: () => ref.invalidate(courseByIdProvider(courseId)),
                ),
              _ => const CourseDetailsSkeleton(),
            },
          ),
        ),
      ),
    );
  }
}
