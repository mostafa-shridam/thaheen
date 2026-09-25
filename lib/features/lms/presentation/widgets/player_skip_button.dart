import 'package:flutter/material.dart';

/// A ±10s control that pulses when tapped.
///
/// Skipping produces no visible change on a static frame, so without this the
/// button gives no sign it registered the tap. The pulse is the acknowledgement.
class PlayerSkipButton extends StatefulWidget {
  const PlayerSkipButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<PlayerSkipButton> createState() => _PlayerSkipButtonState();
}

class _PlayerSkipButtonState extends State<PlayerSkipButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  /// Out and back in one pass, so a rapid double-tap restarts cleanly rather
  /// than leaving the icon stranded at full scale.
  late final Animation<double> _scale =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1,
            end: 1.18,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1.18,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 1,
        ),
      ]).animate(_pulse);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pulse.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        onPressed: _handleTap,
        icon: Icon(widget.icon),
        color: Colors.white,
        iconSize: 32,
        tooltip: widget.tooltip,
      ),
    );
  }
}
