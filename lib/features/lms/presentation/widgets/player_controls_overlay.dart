import 'package:flutter/material.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/player_bottom_row.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/player_seek_bar.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/player_transport_row.dart';
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
///
/// Each part — transport row, seek bar, bottom row — lives in its own file;
/// this widget only composes them and owns the reveal transition.
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
                  child: PlayerTransportRow(
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
                        PlayerSeekBar(
                          position: position,
                          duration: duration,
                          onSeek: onSeek,
                        ),
                        PlayerBottomRow(
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
