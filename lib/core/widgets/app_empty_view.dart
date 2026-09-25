import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';

/// A calm "there is nothing here yet" state.
///
/// Distinct from [AppErrorView] on purpose: an empty course is not a failure,
/// and dressing it up in error styling would tell the student something is
/// broken when nothing is.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.messageKey,
    this.hintKey,
    this.icon = Icons.inbox_rounded,
    this.compact = false,
  });

  /// Translation key for the headline. Never a literal string.
  final String messageKey;

  /// Optional supporting line.
  final String? hintKey;

  final IconData icon;

  /// Tighter spacing for use inside a section rather than a whole screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.palette;

    return Padding(
      padding: EdgeInsetsDirectional.all(compact ? 16 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: compact ? 28 : 40, color: palette.locked),
          SizedBox(height: compact ? 8 : 14),
          Text(
            messageKey.tr(),
            style: compact ? theme.textTheme.bodySmall : theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (hintKey != null && !compact) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              hintKey!.tr(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
