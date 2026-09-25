import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/core/utils/duration_format.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/playback_speed_sheet.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';
import 'package:video_player/video_player.dart';

/// The transport controls drawn over the video surface.
///
/// Rebuilt by a `ValueListenableBuilder` on the controller — which is itself a
/// `ValueNotifier<VideoPlayerValue>` — so a position tick repaints this overlay
/// and nothing else on the page.
///
/// **Motion**: the overlay owns its own show/hide transition rather than being
/// faded by the page. Hiding is not one animation but three that share a
/// duration — the scrim fades, the transport row shrinks back, and the bottom
/// bar drops away — which reads as the chrome stepping aside instead of a flat
/// dissolve. Everything here is implicit animation; there is no controller to
/// keep in sync with playback.
///
/// **RTL**: the control row and the timecode row are plain `Row`s, so Flutter
/// mirrors them in Arabic. The seek `Slider` respects `Directionality` too and
/// fills from the right, which matches the rewind control sitting on the right.
/// The slide and scale transitions are vertical or uniform, so there is nothing
/// in the motion for RTL to get wrong.
class PlayerControlsOverlay extends StatelessWidget {
  const PlayerControlsOverlay({
    super.key,
    required this.controller,
    required this.visible,
    required this.speed,
    required this.isFullscreen,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onSpeedChanged,
    required this.onToggleFullscreen,
  });

  final VideoPlayerController controller;

  /// Whether the chrome is showing. Drives every transition below.
  final bool visible;
  final double speed;
  final bool isFullscreen;
  final VoidCallback onTogglePlay;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onToggleFullscreen;

  static const Duration _skip = Duration(seconds: 10);
  static const Duration _reveal = Duration(milliseconds: 220);

  void _skipBy(VideoPlayerValue value, Duration delta) {
    final target = value.position + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > value.duration
        ? value.duration
        : target;
    onSeek(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final duration = value.duration;
        final position = value.position > duration ? duration : value.position;
        final isFinished = duration > Duration.zero && position >= duration;

        return AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: _reveal,
          curve: Curves.easeOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const <double>[0, 0.4, 1],
              ),
            ),
            child: Column(
              children: <Widget>[
                const Spacer(flex: 2),
                AnimatedScale(
                  scale: visible ? 1 : 0.85,
                  duration: _reveal,
                  curve: Curves.easeOutBack,
                  child: _TransportRow(
                    isPlaying: value.isPlaying,
                    isFinished: isFinished,
                    onTogglePlay: onTogglePlay,
                    onRewind: () => _skipBy(value, -_skip),
                    onForward: () => _skipBy(value, _skip),
                  ),
                ),
                const Spacer(),
                AnimatedSlide(
                  offset: visible ? Offset.zero : const Offset(0, 0.4),
                  duration: _reveal,
                  curve: Curves.easeOutCubic,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                    child: Column(
                      children: <Widget>[
                        _SeekBar(
                          position: position,
                          duration: duration,
                          onSeek: onSeek,
                        ),
                        _BottomRow(
                          position: position,
                          duration: duration,
                          speed: speed,
                          isFullscreen: isFullscreen,
                          onSpeedChanged: onSpeedChanged,
                          onToggleFullscreen: onToggleFullscreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Rewind / play / forward. A `Row`, so Arabic puts rewind on the right.
class _TransportRow extends StatelessWidget {
  const _TransportRow({
    required this.isPlaying,
    required this.isFinished,
    required this.onTogglePlay,
    required this.onRewind,
    required this.onForward,
  });

  final bool isPlaying;
  final bool isFinished;
  final VoidCallback onTogglePlay;
  final VoidCallback onRewind;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _SkipButton(
          icon: Icons.replay_10_rounded,
          tooltip: LocaleKeys.player_rewind.tr(),
          onPressed: onRewind,
        ),
        const SizedBox(width: 18),
        _PlayButton(
          isPlaying: isPlaying,
          isFinished: isFinished,
          onPressed: onTogglePlay,
        ),
        const SizedBox(width: 18),
        _SkipButton(
          icon: Icons.forward_10_rounded,
          tooltip: LocaleKeys.player_forward.tr(),
          onPressed: onForward,
        ),
      ],
    );
  }
}

/// A ±10s control that pulses when tapped.
///
/// Skipping produces no visible change on a static frame, so without this the
/// button gives no sign it registered the tap. The pulse is the acknowledgement.
class _SkipButton extends StatefulWidget {
  const _SkipButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton>
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

/// Play / pause / replay.
///
/// Play and pause morph into each other with [AnimatedIcons.play_pause] rather
/// than cutting, which is what makes the most-tapped control in the app feel
/// responsive. Replay is a different glyph with no morph available, so it
/// cross-fades in instead.
class _PlayButton extends StatefulWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isFinished,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool isFinished;
  final VoidCallback onPressed;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    // Seeded from the current state so resuming a lesson mid-playback opens
    // with the pause glyph already drawn, not mid-morph.
    value: widget.isPlaying ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant _PlayButton oldWidget) {
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

/// The scrub bar. `Slider` is `Directionality`-aware, so in Arabic it fills
/// from the right — the requirement in `docs/DESIGN_SYSTEM.md`.
class _SeekBar extends StatelessWidget {
  const _SeekBar({
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

/// Timecodes on the leading side, speed and fullscreen on the trailing side.
class _BottomRow extends StatelessWidget {
  const _BottomRow({
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
