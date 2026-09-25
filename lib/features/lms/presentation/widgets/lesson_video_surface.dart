import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/player_controls_overlay.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';
import 'package:video_player/video_player.dart';

/// The video frame itself, plus the controls layered over it.
///
/// A real widget rather than a `Widget _buildSurface()` helper on the player's
/// state, so it gets its own element and only rebuilds when one of these
/// arguments actually changes.
class LessonVideoSurface extends StatelessWidget {
  const LessonVideoSurface({
    super.key,
    required this.controller,
    required this.controlsVisible,
    required this.speed,
    required this.isFullscreen,
    required this.onToggleControls,
    required this.onTogglePlay,
    required this.onSeek,
    required this.onSpeedChanged,
    required this.onToggleFullscreen,
  });

  /// Null until the asset has been opened, which is the loading state.
  final VideoPlayerController? controller;
  final ValueNotifier<bool> controlsVisible;
  final double speed;
  final bool isFullscreen;
  final VoidCallback onToggleControls;
  final VoidCallback onTogglePlay;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;

    if (controller == null || !controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  LocaleKeys.player_loading.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // The video frame keeps its own aspect ratio; breakpoints govern the
    // surrounding chrome, not the surface. See docs/DESIGN_SYSTEM.md.
    final surface = AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          VideoPlayer(controller),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleControls,
              child: ValueListenableBuilder<bool>(
                valueListenable: controlsVisible,
                // The overlay owns the show/hide transition now — it fades the
                // scrim, shrinks the transport row and drops the bottom bar as
                // one gesture. All this has left to do is stop a hidden overlay
                // from swallowing the tap that reveals it.
                builder: (context, visible, _) => IgnorePointer(
                  ignoring: !visible,
                  child: PlayerControlsOverlay(
                    controller: controller,
                    visible: visible,
                    speed: speed,
                    isFullscreen: isFullscreen,
                    onTogglePlay: onTogglePlay,
                    onSeek: onSeek,
                    onSpeedChanged: onSpeedChanged,
                    onToggleFullscreen: onToggleFullscreen,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return isFullscreen ? surface : ColoredBox(color: Colors.black, child: surface);
  }
}
