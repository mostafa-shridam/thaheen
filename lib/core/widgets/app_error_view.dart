import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/core/error/failures.dart';
import 'package:thaheen_task/core/localization/failure_translations.dart';
import 'package:thaheen_task/core/widgets/app_container.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// The app's only error surface.
///
/// Every failure — a missing catalogue, a corrupt `.mp4`, an unopenable Hive
/// box — lands here as a calm card with a retry affordance. Nothing in this app
/// is allowed to render a red screen, so widgets that can fail wrap themselves
/// in this rather than letting an exception escape.
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.failure, this.onRetry});

  /// Builds a view from any thrown object, classifying it on the way in.
  AppErrorView.fromError(Object error, {super.key, this.onRetry})
      : failure = AppFailure.from(error);

  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppContainer(
              shape: AppSurfaceShape.circle,
              color: theme.colorScheme.error.withValues(alpha: 0.10),
              padding: const EdgeInsetsDirectional.all(16),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              failure.messageKey.tr(),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              failure.hintKey.tr(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(LocaleKeys.common_retry.tr()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
