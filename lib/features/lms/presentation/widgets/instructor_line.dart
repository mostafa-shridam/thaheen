import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';

/// An instructor's name with its leading icon.
///
/// Shared by the course card and the course-details header, which differ only
/// in whether they append a lesson count — hence [trailing].
///
/// A `Row` rather than hand-placed padding, so the icon lands on the correct
/// side of the name in both Arabic and English without a direction check.
class InstructorLine extends StatelessWidget {
  const InstructorLine({super.key, required this.name, this.trailing});

  final String name;

  /// Optional widget pinned to the end of the row.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Icon(
          Icons.person_outline_rounded,
          size: 16,
          color: theme.palette.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
      ],
    );
  }
}
