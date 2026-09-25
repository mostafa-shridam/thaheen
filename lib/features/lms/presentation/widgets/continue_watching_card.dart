import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/core/utils/duration_format.dart';
import 'package:thaheen_task/core/widgets/app_chip.dart';
import 'package:thaheen_task/core/widgets/app_container.dart';
import 'package:thaheen_task/core/widgets/app_progress_bar.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// The "continue watching" banner at the top of the courses list.
///
/// Shown only when something is genuinely part-watched, so a fresh install has
/// a clean first screen rather than an empty promise.
///
/// Painted on the primary colour, so every child that would normally take a
/// theme default is handed the inverse pair explicitly.
class ContinueWatchingCard extends StatelessWidget {
  const ContinueWatchingCard({super.key, required this.target, this.onTap});

  final ResumeTarget target;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onPrimary.withValues(alpha: 0.75);

    return AppContainer(
      color: scheme.primary,
      padding: const EdgeInsetsDirectional.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.history_rounded, size: 18, color: muted),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.continueWatching_title.tr(),
                style: theme.textTheme.labelLarge?.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            target.lesson.title,
            style: theme.textTheme.titleMedium?.copyWith(color: scheme.onPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            target.course.title,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          AppProgressBar(
            value: target.watchedRatio,
            height: 5,
            color: scheme.onPrimary,
            trackColor: scheme.onPrimary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  LocaleKeys.continueWatching_resumeAt.tr(
                    namedArgs: <String, String>{
                      'time': formatClockFromSeconds(target.progress.positionSec),
                    },
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
              // A chip, not a button: the whole card is already one tap target
              // and a nested button would compete with it.
              AppChip(
                icon: Icons.play_arrow_rounded,
                label: LocaleKeys.continueWatching_action.tr(),
                foreground: scheme.primary,
                background: scheme.onPrimary,
                emphasize: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
