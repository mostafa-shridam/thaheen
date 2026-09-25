import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/widgets/app_empty_view.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/continue_watching_card.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_card.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_search_field.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// The loaded state of the courses screen: search box, resume card, and list.
///
/// Takes the search [query] and its [searchController] from the page rather
/// than owning them, so the text survives this widget rebuilding.
class CoursesListView extends ConsumerWidget {
  const CoursesListView({
    super.key,
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

    final padding = AppBreakpoints.pagePadding(context);
    final resume = ref.watch(continueWatchingProvider);

    return ValueListenableBuilder<String>(
      valueListenable: query,
      builder: (context, searchTerm, _) {
        final visible = filter(courses, searchTerm);

        return CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsetsDirectional.fromSTEB(padding, 8, padding, 0),
              sliver: SliverToBoxAdapter(
                child: CourseSearchField(
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
  static List<CourseModel> filter(List<CourseModel> courses, String term) {
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
