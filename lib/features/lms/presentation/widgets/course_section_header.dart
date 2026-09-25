import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/core/widgets/app_container.dart';
import 'package:thaheen_task/features/lms/data/models/section_model.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// One section's title, with its lesson count on the trailing side.
class CourseSectionHeader extends StatelessWidget {
  const CourseSectionHeader({super.key, required this.section});

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
