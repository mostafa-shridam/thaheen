import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/core/widgets/app_chip.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_progress_bar.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_thumbnail.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/instructor_line.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// One course in the courses list: cover, title, instructor, lesson count and
/// completion bar.
///
/// The card itself is a plain `StatelessWidget`; only [CourseProgressBar]
/// listens to progress, so a change in one course's percentage repaints a
/// 6-pixel bar rather than the whole list.
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.onTap});

  final CourseModel course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // `Card` rather than AppContainer: the shape, border and elevation already
    // come from `cardTheme`, and the thumbnail must clip to the top corners.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CourseThumbnail(assetPath: course.thumbnail),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    course.title,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  InstructorLine(name: course.instructor),
                  const SizedBox(height: 12),
                  AppChip(
                    icon: Icons.play_circle_outline_rounded,
                    label: LocaleKeys.courses_lessonCount
                        .plural(course.lessonCount),
                  ),
                  const SizedBox(height: 14),
                  CourseProgressBar(course: course),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
