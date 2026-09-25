import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thaheen_task/core/error/failures.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/settings/settings_store.dart';
import 'package:thaheen_task/core/widgets/app_error_view.dart';
import 'package:thaheen_task/core/widgets/app_snack_bar.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_progress_model.dart';
import 'package:thaheen_task/features/lms/presentation/pages/course_details_page.dart';
import 'package:thaheen_task/features/lms/presentation/pages/lesson_player_page.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/lesson_footer.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/lesson_player_shell.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/lesson_video_surface.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';
import 'package:video_player/video_player.dart';

/// Owns the video controller for exactly one lesson.
///
/// Built only once the course and lesson are known to exist and the lesson is
/// known to be unlocked, so everything here works against concrete data.
class LessonPlayerView extends ConsumerStatefulWidget {
  const LessonPlayerView({super.key, required this.course, required this.lesson});

  final CourseModel course;
  final LessonModel lesson;

  @override
  ConsumerState<LessonPlayerView> createState() => _LessonPlayerViewState();
}

class _LessonPlayerViewState extends ConsumerState<LessonPlayerView>
    with WidgetsBindingObserver {
  static const Duration _controlsHideAfter = Duration(seconds: 3);

  VideoPlayerController? _controller;
  AppFailure? _failure;
  Timer? _hideControlsTimer;

  /// Whole second most recently handed to the progress controller.
  ///
  /// The player ticks several times a second; progress only needs one update
  /// per second, and this is what throttles it down to that.
  int _lastRecordedSecond = -1;

  /// Local UI state, kept off the provider graph so toggling the overlay never
  /// rebuilds the page or the video surface.
  final ValueNotifier<bool> _controlsVisible = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isFullscreen = ValueNotifier<bool>(false);

  double _speed = 1;
  bool _celebratedCompletion = false;

  /// Captured in [initState] rather than read in [dispose].
  ///
  /// `dispose` runs while the element is being torn down, and reading from
  /// `ref` at that point is unsafe — the scope may already be gone. The
  /// controller is `keepAlive`, so holding the notifier for the lifetime of
  /// this page is both safe and stable.
  late final ProgressController _progress =
      ref.read(progressControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speed = SettingsStore.readPlaybackSpeed();
    // Touch the notifier now, so the final flush in `dispose` never needs `ref`.
    _progress;
    unawaited(_openVideo());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();

    // Capture the final position before tearing the controller down — this is
    // what makes "resume where I left off" work when the student taps back.
    _persistNow();

    _controller?.dispose();
    _controlsVisible.dispose();
    _isFullscreen.dispose();
    unawaited(_restoreOrientation());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller?.pause();
      _persistNow();
    }
  }

  // --- Video lifecycle ----------------------------------------------------

  Future<void> _openVideo() async {
    final controller = VideoPlayerController.asset(widget.lesson.video);
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      // Resume: seek before the first frame is shown so the student never sees
      // the video snap backwards after it starts.
      final saved = ref.read(progressControllerProvider).forLesson(widget.lesson.id);
      final resumeAt = _resumePosition(saved.positionSec, controller.value.duration);
      if (resumeAt > Duration.zero) {
        await controller.seekTo(resumeAt);
        _announceResume(resumeAt);
      }

      await controller.setPlaybackSpeed(_speed);
      controller.addListener(_onControllerTick);

      setState(() {});
      _scheduleControlsHide();
    } on Object catch (error) {
      // A missing or undecodable asset lands here, becomes a calm error card,
      // and never reaches the framework as an unhandled exception.
      if (!mounted) return;
      setState(() {
        _failure = AppFailure(
          FailureCode.videoUnavailable,
          debugDetail: '${widget.lesson.video}: $error',
        );
      });
    }
  }

  /// Where to drop the playhead on reopen.
  ///
  /// A lesson watched to the very end resumes at the start instead of sitting
  /// on the final frame with nothing left to play.
  Duration _resumePosition(int savedSeconds, Duration duration) {
    if (savedSeconds <= 0) return Duration.zero;
    final saved = Duration(seconds: savedSeconds);
    if (duration > Duration.zero && saved >= duration - const Duration(seconds: 1)) {
      return Duration.zero;
    }
    return saved;
  }

  void _announceResume(Duration at) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: LocaleKeys.player_resumedFrom.tr(
          namedArgs: <String, String>{'time': _clock(at)},
        ),
        icon: Icons.history_rounded,
        duration: const Duration(seconds: 2),
      );
    });
  }

  static String _clock(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Fires several times a second while the video plays.
  ///
  /// This is what keeps the rest of the app live: recording here means the
  /// lesson's progress bar, the course percentage and the next-lesson button
  /// all follow the playhead. Previously nothing recorded between the 5-second
  /// save timer's ticks — and that timer was skipped once playback stopped —
  /// so a lesson finished watching only registered after leaving the player.
  void _onControllerTick() {
    final controller = _controller;
    if (controller == null || !mounted) return;

    if (controller.value.hasError && _failure == null) {
      setState(() {
        _failure = AppFailure(
          FailureCode.videoUnavailable,
          debugDetail: controller.value.errorDescription,
        );
      });
      return;
    }

    if (!controller.value.isInitialized) return;

    // Throttle to whole seconds: finer granularity would not change anything
    // the student can see.
    final second = controller.value.position.inSeconds;
    if (second == _lastRecordedSecond) return;
    _lastRecordedSecond = second;

    _record();
  }

  // --- Progress persistence ----------------------------------------------

  /// Pushes the current position through the single rule path.
  ///
  /// Updates shared state immediately; the controller decides when that
  /// reaches disk.
  void _record() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final future = _progress.record(
      lessonId: widget.lesson.id,
      positionSec: controller.value.position.inSeconds,
      reportedDurationSec: controller.value.duration.inSeconds,
      declaredDurationSec: widget.lesson.durationSec,
    );

    unawaited(future.then(_onRecorded));
  }

  /// Records *and* forces the write to disk.
  ///
  /// For the moments where the next thing to happen might be the process
  /// dying: pausing, leaving the lesson, or the app going to the background.
  void _persistNow() {
    _record();
    unawaited(_progress.flush());
  }

  /// Celebrates crossing the 90% line exactly once per visit.
  void _onRecorded(bool justCompleted) {
    if (!justCompleted || _celebratedCompletion || !mounted) return;
    _celebratedCompletion = true;

    AppSnackBar.show(
      context,
      message: LocaleKeys.lesson_completedToast.tr(),
      kind: AppSnackBarKind.success,
      duration: const Duration(seconds: 2),
    );
  }

  // --- Controls -----------------------------------------------------------

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
      // Pausing is a natural save point: the student may be about to leave.
      _persistNow();
      _showControls(autoHide: false);
    } else {
      final atEnd = controller.value.position >= controller.value.duration &&
          controller.value.duration > Duration.zero;
      if (atEnd) unawaited(controller.seekTo(Duration.zero));
      unawaited(controller.play());
      _showControls();
    }
  }

  Future<void> _seek(Duration target) async {
    await _controller?.seekTo(target);
    // A seek jumps the playhead, so let the next tick through even if it lands
    // back on the second we just recorded.
    _lastRecordedSecond = -1;
    _record();
    _showControls();
  }

  Future<void> _setSpeed(double speed) async {
    await _controller?.setPlaybackSpeed(speed);
    // Remembered across lessons and restarts — one of the task's bonus items.
    await SettingsStore.writePlaybackSpeed(speed);
    if (mounted) setState(() => _speed = speed);
  }

  void _showControls({bool autoHide = true}) {
    _controlsVisible.value = true;
    _hideControlsTimer?.cancel();
    if (autoHide) _scheduleControlsHide();
  }

  void _toggleControls() =>
      _controlsVisible.value ? _controlsVisible.value = false : _showControls();

  void _scheduleControlsHide() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(_controlsHideAfter, () {
      if (_controller?.value.isPlaying ?? false) _controlsVisible.value = false;
    });
  }

  Future<void> _toggleFullscreen() async {
    final entering = !_isFullscreen.value;
    _isFullscreen.value = entering;

    if (entering) {
      await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await _restoreOrientation();
    }
    _showControls();
  }

  /// Puts the device back the way `main()` left it.
  Future<void> _restoreOrientation() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _openNext(LessonModel next) => context.pushReplacementNamed(
        LessonPlayerPage.routeName,
        pathParameters: <String, String>{
          CourseDetailsPage.courseIdParam: widget.course.id,
          LessonPlayerPage.lessonIdParam: next.id,
        },
      );

  // --- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure != null) {
      return LessonPlayerShell(
        title: widget.lesson.title,
        child: AppErrorView(
          failure: failure,
          onRetry: () {
            setState(() => _failure = null);
            unawaited(_openVideo());
          },
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _isFullscreen,
      builder: (context, fullscreen, _) {
        if (fullscreen) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: _surface(fullscreen: true)),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.lesson.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.contentMaxWidth,
                ),
                child: Column(
                  children: <Widget>[
                    _surface(fullscreen: false),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsetsDirectional.all(16),
                        child: LessonFooter(
                          course: widget.course,
                          lesson: widget.lesson,
                          onOpenNext: _openNext,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Binds this state's callbacks to [LessonVideoSurface] for both layouts.
  LessonVideoSurface _surface({required bool fullscreen}) => LessonVideoSurface(
        controller: _controller,
        controlsVisible: _controlsVisible,
        speed: _speed,
        isFullscreen: fullscreen,
        onToggleControls: _toggleControls,
        onTogglePlay: _togglePlay,
        onSeek: _seek,
        onSpeedChanged: _setSpeed,
        onToggleFullscreen: _toggleFullscreen,
      );
}
