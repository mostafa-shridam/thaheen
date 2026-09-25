import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Play / pause / replay.
///
/// Play and pause morph into each other with [AnimatedIcons.play_pause] rather
/// than cutting, which is what makes the most-tapped control in the app feel
/// responsive. Replay is a different glyph with no morph available, so it
/// cross-fades in instead.
class PlayerPlayButton extends StatefulWidget {
  const PlayerPlayButton({
    super.key,
    required this.isPlaying,
    required this.isFinished,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool isFinished;
  final VoidCallback onPressed;

  @override
  State<PlayerPlayButton> createState() => _PlayerPlayButtonState();
}

class _PlayerPlayButtonState extends State<PlayerPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    // Seeded from the current state so resuming a lesson mid-playback opens
    // with the pause glyph already drawn, not mid-morph.
    value: widget.isPlaying ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant PlayerPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying == oldWidget.isPlaying) return;
    if (widget.isPlaying) {
      _morph.forward();
    } else {
      _morph.reverse();
    }
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tooltipKey = widget.isFinished
        ? LocaleKeys.player_replay
        : widget.isPlaying
        ? LocaleKeys.player_pause
        : LocaleKeys.player_play;

    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: widget.onPressed,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltipKey.tr(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.isFinished
                  ? const Icon(
                      Icons.replay_rounded,
                      key: ValueKey<bool>(true),
                      color: Colors.white,
                      size: 40,
                    )
                  : AnimatedIcon(
                      key: const ValueKey<bool>(false),
                      icon: AnimatedIcons.play_pause,
                      progress: _morph,
                      color: Colors.white,
                      size: 40,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
