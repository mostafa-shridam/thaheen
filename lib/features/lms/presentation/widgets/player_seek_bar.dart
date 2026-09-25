import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// The scrub bar. `Slider` is `Directionality`-aware, so in Arabic it fills
/// from the right — the requirement in `docs/DESIGN_SYSTEM.md`.
class PlayerSeekBar extends StatelessWidget {
  const PlayerSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final totalMs = duration.inMilliseconds;
    final positionMs = position.inMilliseconds.clamp(
      0,
      totalMs == 0 ? 1 : totalMs,
    );

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
        thumbColor: Colors.white,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      child: Semantics(
        label: LocaleKeys.player_seekBarLabel.tr(),
        child: Slider(
          value: positionMs.toDouble(),
          max: (totalMs == 0 ? 1 : totalMs).toDouble(),
          // Disabled until the duration is known, so an un-initialised video
          // cannot be scrubbed into a bad position.
          onChanged: totalMs == 0
              ? null
              : (value) => onSeek(Duration(milliseconds: value.round())),
        ),
      ),
    );
  }
}
