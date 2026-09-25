import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:thaheen_task/core/error/failures.dart';
import 'package:thaheen_task/core/widgets/app_error_view.dart';
import 'package:thaheen_task/features/lms/presentation/pages/course_details_page.dart';
import 'package:thaheen_task/features/lms/presentation/pages/courses_page.dart';
import 'package:thaheen_task/features/lms/presentation/pages/lesson_player_page.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

part 'app_router.g.dart';

/// The app's navigation graph.
///
/// Routes nest, so the locations mirror the hierarchy a student walks:
/// `/` -> `/courses/:courseId` -> `/courses/:courseId/lessons/:lessonId`.
/// Each page declares its own path fragment and parameter names; this file only
/// assembles them.
///
/// Deep-link safety lives in the pages, not in a router `redirect`: a link into
/// a locked lesson opens the player route and is met with the same explanation
/// the lesson list gives, rather than a silent bounce the student cannot read.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => GoRouter(
      initialLocation: CoursesPage.routePath,
      routes: <RouteBase>[
        GoRoute(
          path: CoursesPage.routePath,
          name: CoursesPage.routeName,
          builder: (context, state) => const CoursesPage(),
          routes: <RouteBase>[
            GoRoute(
              path: CourseDetailsPage.routePath,
              name: CourseDetailsPage.routeName,
              builder: (context, state) => CourseDetailsPage(
                courseId:
                    state.pathParameters[CourseDetailsPage.courseIdParam] ?? '',
              ),
              routes: <RouteBase>[
                GoRoute(
                  path: LessonPlayerPage.routePath,
                  name: LessonPlayerPage.routeName,
                  builder: (context, state) => LessonPlayerPage(
                    courseId: state
                            .pathParameters[CourseDetailsPage.courseIdParam] ??
                        '',
                    lessonId:
                        state.pathParameters[LessonPlayerPage.lessonIdParam] ??
                            '',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],

      // An unknown location is a bug, not a student-facing catastrophe: show
      // the same calm error card everything else uses.
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.errors_title.tr())),
        body: AppErrorView(
          failure: AppFailure(
            FailureCode.unexpected,
            debugDetail: 'no route for ${state.uri}',
          ),
          onRetry: () => context.goNamed(CoursesPage.routeName),
        ),
      ),
    );
