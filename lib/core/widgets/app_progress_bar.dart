import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';

/// The app's only progress bar.
///
/// Every completion bar in Thaheen is this widget: the course card, the course
/// header, the lesson tile's resume strip and the continue-watching banner.
/// They differ only in thickness and colour, which is exactly what the two
/// optional parameters are for — the pill shape, the clamping and the track
/// treatment stay identical everywhere because there is one implementation.
///
/// [color] and [trackColor] default to the theme, so a caller only names them
/// when it sits on a non-standard surface — the continue-watching card, which
/// is painted on the primary colour and needs the inverse pair.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.trackColor,
  });

  /// Completion in `0.0..1.0`. Clamped, so a caller cannot paint past the end
  /// with a stale ratio.
  final double value;

  final double height;

  /// Defaults to `colorScheme.primary`.
  final Color? color;

  /// Defaults to the palette's border colour.
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      // Fully rounded: the radius is larger than any height this is used at,
      // so the ends are always semicircular.
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: trackColor ?? theme.palette.border,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}
