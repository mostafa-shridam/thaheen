import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thaheen_task/core/error/failures.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/settings/settings_store.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';
import 'package:thaheen_task/core/widgets/app_error_view.dart';
import 'package:thaheen_task/core/widgets/app_snack_bar.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_progress_model.dart';
import 'package:thaheen_task/features/lms/presentation/pages/course_details_page.dart';
import 'package:thaheen_task/features/lms/presentation/providers/catalogue_providers.dart';
import 'package:thaheen_task/features/lms/presentation/providers/progress_providers.dart';
import 'package:thaheen_task/features/lms/presentation/widgets/player_controls_overlay.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';
import 'package:video_player/video_player.dart';

/// Plays one lesson.
///
/// Resolves the course and lesson first so the player itself can be built
/// against concrete, non-null data — the video controller is created exactly
/// once, in a widget that already knows which asset it is playing.
class LessonPlayerPage extends ConsumerWidget {
  const LessonPlayerPage({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  static const String routeName = 'lesson-player';

  /// Declared relative to [CourseDetailsPage]'s route.
  static const String routePath = 'lessons/:lessonId';
  static const String lessonIdParam = 'lessonId';

  final String courseId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseByIdProvider(courseId));

    return switch (course) {
      AsyncData(value: final CourseModel loaded) => _resolveLesson(context, loaded, ref),
      AsyncError(:final error) => _Shell(
          child: AppErrorView.fromError(
            error,
            onRetry: () => ref.invalidate(courseByIdProvider(courseId)),
          ),
        ),
      _ => const _Shell(child: Center(child: CircularProgressIndicator())),
    };
  }

  Widget _resolveLesson(BuildContext context, CourseModel course, WidgetRef ref) {
    final lesson = course.lessonById(lessonId);
    if (lesson == null) {
      return const _Shell(
        child: AppErrorView(
          failure: AppFailure(
            FailureCode.catalogueCorrupt,
            debugDetail: 'lesson id not in course',
          ),
        ),
      );
    }

    // A deep link into a still-locked lesson is refused here rather than in the
    // router, so the student gets the same explanation the lesson list gives.
    final progress = ref.watch(progressControllerProvider);
    if (!course.isLessonUnlocked(lesson.id, progress)) {
      return _Shell(
        title: lesson.title,
        child: _LockedNotice(course: course, lesson: lesson),
      );
    }

    return _PlayerView(course: course, lesson: lesson);
  }
}

/// Scaffold used for every non-playing state, so they all share one chrome.
class _Shell extends StatelessWidget {
  const _Shell({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            title ?? LocaleKeys.app_name.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(child: child),
      );
}

class _LockedNotice extends StatelessWidget {
  const _LockedNotice({required this.course, required this.lesson});

  final CourseModel course;
  final LessonModel lesson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocking = course.blockingLessonFor(lesson.id);

    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.lock_outline_rounded, size: 40, color: theme.palette.locked),
            const SizedBox(height: 14),
            Text(
              LocaleKeys.lesson_lockedTitle.tr(),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              blocking == null
                  ? LocaleKeys.lesson_lockedMessageGeneric.tr()
                  : LocaleKeys.lesson_lockedMessage
                      .tr(namedArgs: <String, String>{'title': blocking.title}),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Owns the video controller for exactly one lesson.
class _PlayerView extends ConsumerStatefulWidget {
  const _PlayerView({required this.course, required this.lesson});

  final CourseModel course;
  final LessonModel lesson;

  @override
  ConsumerState<_PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends ConsumerState<_PlayerView> with WidgetsBindingObserver {
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

  // --- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure != null) {
      return _Shell(
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
            body: Center(child: _buildSurface(fullscreen: true)),
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
                    _buildSurface(fullscreen: false),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsetsDirectional.all(16),
                        child: _LessonFooter(
                          course: widget.course,
                          lesson: widget.lesson,
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

  Widget _buildSurface({required bool fullscreen}) {
    final controller = _controller;

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
              onTap: () => _controlsVisible.value
                  ? _controlsVisible.value = false
                  : _showControls(),
              child: ValueListenableBuilder<bool>(
                valueListenable: _controlsVisible,
                // The overlay owns the show/hide transition now — it fades the
                // scrim, shrinks the transport row and drops the bottom bar as
                // one gesture. All this has left to do is stop a hidden overlay
                // from swallowing the tap that reveals it.
                builder: (context, visible, _) => IgnorePointer(
                  ignoring: !visible,
                  child: PlayerControlsOverlay(
                    controller: controller,
                    visible: visible,
                    speed: _speed,
                    isFullscreen: fullscreen,
                    onTogglePlay: _togglePlay,
                    onSeek: _seek,
                    onSpeedChanged: _setSpeed,
                    onToggleFullscreen: _toggleFullscreen,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return fullscreen ? surface : ColoredBox(color: Colors.black, child: surface);
  }
}

/// Everything below the video: the next-lesson call to action.
class _LessonFooter extends ConsumerWidget {
  const _LessonFooter({required this.course, required this.lesson});

  final CourseModel course;
  final LessonModel lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(progressControllerProvider);
    final next = course.lessonAfter(lesson.id);

    if (next == null) {
      return _FooterNote(
        icon: Icons.flag_outlined,
        text: course.isCompleted(progress)
            ? LocaleKeys.lesson_courseFinished.tr()
            : LocaleKeys.lesson_isLastLesson.tr(),
      );
    }

    final unlocked = course.isLessonUnlocked(next.id, progress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(lesson.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        FilledButton.icon(
          // Shown disabled rather than hidden: the student can see what comes
          // next and what it will take to get there.
          onPressed: unlocked
              ? () => context.pushReplacementNamed(
                    LessonPlayerPage.routeName,
                    pathParameters: <String, String>{
                      CourseDetailsPage.courseIdParam: course.id,
                      LessonPlayerPage.lessonIdParam: next.id,
                    },
                  )
              : null,
          icon: Icon(unlocked ? Icons.skip_next_rounded : Icons.lock_outline_rounded),
          label: Text(LocaleKeys.lesson_next.tr()),
        ),
        const SizedBox(height: 8),
        Text(
          unlocked ? next.title : LocaleKeys.lesson_nextLocked.tr(),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: theme.palette.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}
