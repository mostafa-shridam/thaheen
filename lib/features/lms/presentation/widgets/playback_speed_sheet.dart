import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';
import 'package:thaheen_task/core/widgets/app_sheet.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Playback speed picker.
///
/// The four speeds the task names, and no more — a long list of rates is a
/// worse experience than four obvious ones.
///
/// The pick is applied through [onSelected] the instant a row is tapped, while
/// the sheet is still open, so the student *hears* the new speed as a result of
/// the tap rather than as a result of the dismissal. The sheet then closes
/// itself. That is why nothing here is returned through `Navigator.pop`: a
/// picker that resolves only on close cannot preview.
class PlaybackSpeedSheet extends StatefulWidget {
  const PlaybackSpeedSheet({
    super.key,
    required this.current,
    required this.onSelected,
  });

  /// The speeds offered, and the single source of truth for what is valid.
  static const List<double> speeds = <double>[1, 1.25, 1.5, 2];

  final double current;

  /// Called the moment a speed is chosen, before the sheet closes.
  final ValueChanged<double> onSelected;

  /// Opens the picker.
  static Future<void> show(
    BuildContext context, {
    required double current,
    required ValueChanged<double> onSelected,
  }) =>
      AppSheet.show<void>(
        context,
        child: PlaybackSpeedSheet(current: current, onSelected: onSelected),
      );

  /// Renders `1×`, `1.25×` — trimming the pointless `.0` on whole speeds.
  static String label(double speed) {
    final text =
        speed == speed.roundToDouble() ? speed.toStringAsFixed(0) : speed.toString();
    return LocaleKeys.player_speedValue
        .tr(namedArgs: <String, String>{'value': text});
  }

  @override
  State<PlaybackSpeedSheet> createState() => _PlaybackSpeedSheetState();
}

class _PlaybackSpeedSheetState extends State<PlaybackSpeedSheet>
    with SingleTickerProviderStateMixin {
  /// Long enough for the tapped row to finish turning selected before the sheet
  /// slides away, short enough that it never reads as lag.
  static const Duration _closeAfter = Duration(milliseconds: 220);

  late double _selected = widget.current;

  /// Drives the staggered entrance. One controller for the whole list; each row
  /// takes its slice of it through an [Interval].
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// The slice of [_entrance] belonging to row [index].
  Animation<double> _rowAnimation(int index) {
    final start = (index * 0.12).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, (start + 0.55).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
  }

  Future<void> _pick(double speed) async {
    // Re-picking the current speed is a dismissal, not a change: close at once
    // rather than replaying a transition that changes nothing.
    if (speed == _selected) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _selected = speed);
    widget.onSelected(speed);

    await Future<void>.delayed(_closeAfter);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: LocaleKeys.player_speedLabel.tr(),
      children: <Widget>[
        for (final (int index, double speed) in PlaybackSpeedSheet.speeds.indexed)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8),
            child: _SpeedOption(
              animation: _rowAnimation(index),
              label: PlaybackSpeedSheet.label(speed),
              selected: speed == _selected,
              onTap: () => _pick(speed),
            ),
          ),
      ],
    );
  }
}

/// One row of the picker: fades and rises in, then animates its selected state.
class _SpeedOption extends StatelessWidget {
  const _SpeedOption({
    required this.animation,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Duration _stateChange = Duration(milliseconds: 220);
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(12));

  final Animation<double> animation;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        // Vertical only, so there is nothing for RTL to mirror.
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(animation),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: _radius,
            child: AnimatedContainer(
              duration: _stateChange,
              curve: Curves.easeOut,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? primary.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: _radius,
                border: Border.all(
                  color: selected ? primary : theme.palette.border,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: _stateChange,
                      curve: Curves.easeOut,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: selected ? primary : null,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      child: Text(label, maxLines: 1),
                    ),
                  ),
                  // Always laid out, scaled to nothing when unselected, so the
                  // row never jumps width as the tick appears.
                  AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: _stateChange,
                    curve: Curves.easeOutBack,
                    child: Icon(Icons.check_circle_rounded, color: primary, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
