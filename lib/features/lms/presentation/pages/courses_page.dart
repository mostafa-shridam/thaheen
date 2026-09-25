import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';
import 'package:thaheen_task/core/theme/app_theme.dart';
import 'package:thaheen_task/core/widgets/app_empty_view.dart';
import 'package:thaheen_task/core/widgets/app_error_view.dart';
import 'package:thaheen_task/core/widgets/app_skeleton_box.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/presentation/pages/course_details_page.dart';
import 'package:thaheen_task/features/lms/presentation/pages/lesson_player_page.dart';
import 'package:thaheen_task/features/lms/presentation/providers/catalogue_providers.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/continue_watching_card.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_card.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/settings_sheet.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Home screen: every course the student owns.
///
/// The four states the task asks for — loading, empty, error, data — are
/// handled explicitly here rather than being left to an unguarded `.value`,
/// which is what keeps a red screen off the device.
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
              AsyncData<List<CourseModel>>(:final value) => _Loaded(
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
              _ => const _CoursesSkeleton(),
            },
          ),
        ),
      ),
    );
  }
}

/// Horizontal page padding, widened past the mobile breakpoint.
///
/// Read through `ResponsiveValue` rather than `MediaQuery` arithmetic, per the
/// responsive rules in `docs/DESIGN_SYSTEM.md`.
double _pagePadding(BuildContext context) => ResponsiveValue<double>(
      context,
      defaultValue: 16,
      conditionalValues: const <Condition<double>>[
        Condition<double>.largerThan(name: MOBILE, value: 24),
      ],
    ).value;

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.courses,
    required this.query,
    required this.searchController,
    required this.onOpenCourse,
    required this.onOpenLesson,
  });

  final List<CourseModel> courses;
  final ValueNotifier<String> query;
  final TextEditingController searchController;
  final ValueChanged<String> onOpenCourse;
  final void Function({required String courseId, required String lessonId}) onOpenLesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (courses.isEmpty) {
      return const Center(
        child: AppEmptyView(
          messageKey: LocaleKeys.courses_empty,
          hintKey: LocaleKeys.courses_emptyHint,
          icon: Icons.school_outlined,
        ),
      );
    }

    final padding = _pagePadding(context);
    final resume = ref.watch(continueWatchingProvider);

    return ValueListenableBuilder<String>(
      valueListenable: query,
      builder: (context, searchTerm, _) {
        final visible = _filter(courses, searchTerm);

        return CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsetsDirectional.fromSTEB(padding, 8, padding, 0),
              sliver: SliverToBoxAdapter(
                child: _SearchField(
                  controller: searchController,
                  onChanged: (value) => query.value = value,
                ),
              ),
            ),

            // The resume card only makes sense over the full catalogue, so it
            // is hidden while a search is narrowing the list.
            if (searchTerm.isEmpty)
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(padding, 16, padding, 0),
                sliver: SliverToBoxAdapter(
                  child: switch (resume) {
                    AsyncData(value: final ResumeTarget target) => ContinueWatchingCard(
                        target: target,
                        onTap: () => onOpenLesson(
                          courseId: target.course.id,
                          lessonId: target.lesson.id,
                        ),
                      ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),

            if (visible.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: AppEmptyView(
                    messageKey: LocaleKeys.courses_searchNoResults,
                    hintKey: LocaleKeys.courses_searchNoResultsHint,
                    icon: Icons.search_off_rounded,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(padding, 16, padding, 24),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => CourseCard(
                    course: visible[index],
                    onTap: () => onOpenCourse(visible[index].id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Matches on title or instructor, case-insensitively.
  ///
  /// Arabic has no case, so `toLowerCase` is a no-op there and the comparison
  /// is a plain substring match — which is the right behaviour for both scripts
  /// without pulling in a collation library.
  static List<CourseModel> _filter(List<CourseModel> courses, String term) {
    final needle = term.trim().toLowerCase();
    if (needle.isEmpty) return courses;
    return <CourseModel>[
      for (final course in courses)
        if (course.title.toLowerCase().contains(needle) ||
            course.instructor.toLowerCase().contains(needle))
          course,
    ];
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: LocaleKeys.courses_searchHint.tr(),
        hintStyle: theme.textTheme.bodySmall,
        // `prefixIcon` is direction-aware: it renders on the right in Arabic.
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: theme.palette.textSecondary,
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsetsDirectional.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          borderSide: BorderSide(color: theme.palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
          borderSide: BorderSide(color: theme.palette.border),
        ),
      ),
    );
  }
}

/// Skeleton mirroring the real card layout, so the swap to content does not
/// shift the page.
class _CoursesSkeleton extends StatelessWidget {
  const _CoursesSkeleton();

  @override
  Widget build(BuildContext context) {
    final padding = _pagePadding(context);
    return ListView.separated(
      padding: EdgeInsetsDirectional.fromSTEB(padding, 8, padding, 24),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AppSkeletonBox(height: double.infinity, radius: 12),
          ),
          SizedBox(height: 12),
          AppSkeletonBox(width: 220, height: 18),
          SizedBox(height: 8),
          AppSkeletonBox(width: 140, height: 12),
          SizedBox(height: 10),
          AppSkeletonBox(width: 90, height: 24, radius: 10),
          SizedBox(height: 14),
          AppSkeletonBox(height: 6, radius: 999),
        ],
      ),
    );
  }
}
