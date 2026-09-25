import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/core/utils/duration_format.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/playback_speed_sheet.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Timecodes on the leading side, speed and fullscreen on the trailing side.
class PlayerBottomRow extends StatelessWidget {
  const PlayerBottomRow({
    super.key,
    required this.position,
    required this.duration,
    required this.speed,
    required this.isFullscreen,
    required this.onSpeedChanged,
    required this.onToggleFullscreen,
  });

  static const Duration _swap = Duration(milliseconds: 240);

  final Duration position;
  final Duration duration;
  final double speed;
  final bool isFullscreen;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context) {
    final timeStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.white);

    return Row(
      children: <Widget>[
        const SizedBox(width: 8),
        // Two separate Text widgets, never one concatenated 'a / b' string —
        // that would flip apart in RTL.
        Text(formatClock(position), style: timeStyle),
        Text('  /  ', style: timeStyle),
        Text(formatClock(duration), style: timeStyle),
        const Spacer(),
        TextButton(
          onPressed: () {
            // The sheet applies the pick itself, through onSpeedChanged, while
            // it is still open — so there is nothing to await and nothing to
            // resolve on close.
            unawaited(
              PlaybackSpeedSheet.show(
                context,
                current: speed,
                onSelected: onSpeedChanged,
              ),
            );
          },
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          // Keyed on the speed, so changing it pops the new rate in rather than
          // swapping the glyph underneath the student's finger.
          child: AnimatedSwitcher(
            duration: _swap,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Text(
              PlaybackSpeedSheet.label(speed),
              key: ValueKey<double>(speed),
            ),
          ),
        ),
        IconButton(
          onPressed: onToggleFullscreen,
          color: Colors.white,
          tooltip:
              (isFullscreen
                      ? LocaleKeys.player_exitFullscreen
                      : LocaleKeys.player_enterFullscreen)
                  .tr(),
          icon: AnimatedSwitcher(
            duration: _swap,
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween<double>(begin: 0.75, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              isFullscreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              key: ValueKey<bool>(isFullscreen),
            ),
          ),
        ),
      ],
    );
  }
}
