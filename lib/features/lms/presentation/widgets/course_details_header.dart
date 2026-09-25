import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_theme.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_progress_bar.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/course_thumbnail.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/instructor_line.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Thumbnail, title, instructor, lesson count and progress bar for one course.
class CourseDetailsHeader extends StatelessWidget {
  const CourseDetailsHeader({super.key, required this.course});

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
