import 'package:flutter/material.dart';
import 'package:thaheen_task/core/widgets/app_container.dart';

/// The app's only chip.
///
/// A pill carrying an optional icon and a short label: the lesson-count badge
/// on a course card, the resume call-to-action on the continue-watching banner,
/// and anything similar that follows. They differ only in colour and emphasis,
/// which is what the parameters are for — the pill shape, the icon gap and the
/// padding are fixed so every chip in the app reads as the same component.
///
/// Not Material's `Chip`: that carries interaction affordances and sizing this
/// design does not want, and overriding them everywhere is more code than this.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.foreground,
    this.background,
    this.emphasize = false,
  });

  final String label;
  final IconData? icon;

  /// Icon and label colour. Defaults to `colorScheme.primary`.
  final Color? foreground;

  /// Defaults to a faint wash of [foreground].
  final Color? background;

  /// Renders the label semibold — for a chip acting as a call to action.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = foreground ?? theme.colorScheme.primary;

    return AppContainer(
      shape: AppSurfaceShape.pill,
      color: background ?? tint.withValues(alpha: 0.08),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: <Widget>[
          if (icon != null) ...[
            Icon(icon, size: 15, color: tint),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: tint,
              fontWeight: emphasize ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}
