import 'package:flutter/material.dart';
import 'package:thaheen_task/core/widgets/app_container.dart';

/// The app's only list row.
///
/// One layout — optional leading, a title with an optional subtitle block, an
/// optional trailing widget — shared by the lesson list and the sheets. Before
/// it existed, each of those hand-rolled the same `Row` with its own spacing.
///
/// [surface] is the one real variation: a row in a list needs the card
/// treatment, a row inside a sheet is already on one and must not draw a second.
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    required this.title,
    this.titleColor,
    this.titleMaxLines = 2,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.surface = true,
  });

  final String title;

  /// Overrides the title colour — used to grey out a locked row.
  final Color? titleColor;

  final int titleMaxLines;

  /// Rendered under the title. A widget, not a string, because callers put
  /// metadata rows and progress bars here.
  final Widget? subtitle;

  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// When true, wraps the row in an [AppContainer] card. Set false inside a
  /// sheet or any parent that already provides the surface.
  final bool surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final row = Row(
      children: <Widget>[
        if (leading != null) ...<Widget>[leading!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(color: titleColor),
                maxLines: titleMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                subtitle!,
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: 8), trailing!],
      ],
    );

    if (!surface) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
          child: row,
        ),
      );
    }

    return AppContainer(
      padding: const EdgeInsetsDirectional.all(12),
      onTap: onTap,
      child: row,
    );
  }
}
