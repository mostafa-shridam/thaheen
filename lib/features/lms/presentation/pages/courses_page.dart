import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/widgets/app_error_view.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/presentation/pages/course_details_page.dart';
import 'package:thaheen_task/features/lms/presentation/pages/lesson_player_page.dart';
import 'package:thaheen_task/features/lms/presentation/providers/catalogue_providers.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/courses_list_view.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/courses_skeleton.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/settings_sheet.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Home screen: every course the student owns.
///
/// The four states the task asks for — loading, empty, error, data — are
/// handled explicitly here rather than being left to an unguarded `.value`,
/// which is what keeps a red screen off the device. The screen itself only
/// wires state to navigation; each state's layout lives in its own widget
/// file under `presentation/widgets/`.
class CoursesPage extends ConsumerStatefulWidget {
  const CoursesPage({super.key});

  /// Declared on the page rather than in a shared route table, so a screen and
  /// the location that reaches it move together.
  static const String routeName = 'courses';
  static const String routePath = '/';

  @override
  ConsumerState<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends ConsumerState<CoursesPage> {
  /// Search text is local UI state, so it lives in a `ValueNotifier` rather than
  /// a provider — typing must not rebuild anything above the list.
  final ValueNotifier<String> _query = ValueNotifier<String>('');
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openCourse(String courseId) =>
      context.pushNamed(CourseDetailsPage.routeName, pathParameters: <String, String>{
        CourseDetailsPage.courseIdParam: courseId,
      });

  void _openLesson({required String courseId, required String lessonId}) =>
      context.pushNamed(LessonPlayerPage.routeName, pathParameters: <String, String>{
        CourseDetailsPage.courseIdParam: courseId,
        LessonPlayerPage.lessonIdParam: lessonId,
      });

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(courseCatalogueProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.courses_title.tr()),
        actions: <Widget>[
          IconButton(
            onPressed: () => SettingsSheet.show(context),
            icon: const Icon(Icons.tune_rounded),
            tooltip: LocaleKeys.settings_title.tr(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMaxWidth,
            ),
            child: switch (catalogue) {
              AsyncData<List<CourseModel>>(:final value) => CoursesListView(
                  courses: value,
                  query: _query,
                  searchController: _searchController,
                  onOpenCourse: _openCourse,
                  onOpenLesson: _openLesson,
                ),
              AsyncError<List<CourseModel>>(:final error) => AppErrorView.fromError(
                  error,
                  onRetry: () => ref.invalidate(courseCatalogueProvider),
                ),
              _ => const CoursesSkeleton(),
            },
          ),
        ),
      ),
    );
  }
}
