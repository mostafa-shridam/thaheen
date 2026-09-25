import 'dart:async';

import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';

/// What a message means, which is all a caller has to decide.
///
/// The colour and the icon follow from the kind, so two success messages raised
/// by different features can never disagree about what success looks like.
enum AppSnackBarKind { info, success, error }

/// The app's only transient message.
///
/// Presented as a **top** overlay rather than a Material `SnackBar`: the player
/// puts its transport controls along the bottom of the video, and in fullscreen
/// a bottom-anchored message lands directly on top of them. Coming down from
/// the status bar keeps every message clear of the controls it is describing.
///
/// Because it is an `OverlayEntry` on the root overlay, it does not need a
/// `Scaffold` in scope and survives a route push underneath it.
///
/// One message is shown at a time: [show] dismisses whatever is up before
/// inserting the next, which is the behaviour the old `hideCurrentSnackBar`
/// calls were reaching for.
class AppSnackBar extends StatelessWidget {
  const AppSnackBar({
    super.key,
    required this.message,
    this.kind = AppSnackBarKind.info,
    this.icon,
  });

  static const Duration _defaultDuration = Duration(seconds: 3);

  static _ActiveSnackBar? _current;

  final String message;
  final AppSnackBarKind kind;

  /// Overrides the icon the [kind] would choose — for a message whose subject
  /// has a glyph of its own, such as a locked lesson.
  final IconData? icon;

  /// Shows [message] over everything, dismissing any message already up.
  ///
  /// Safe to call from a context with no overlay — it does nothing rather than
  /// throwing, so a message raised during teardown cannot crash a page.
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarKind kind = AppSnackBarKind.info,
    IconData? icon,
    Duration duration = _defaultDuration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    dismiss();

    late final _ActiveSnackBar active;
    final entry = OverlayEntry(
      builder: (context) => _SnackBarHost(
        duration: duration,
        onDismissed: () {
          active.remove();
          if (identical(_current, active)) _current = null;
        },
        child: AppSnackBar(message: message, kind: kind, icon: icon),
      ),
    );

    active = _ActiveSnackBar(entry);
    _current = active;
    overlay.insert(entry);
  }

  /// Removes the current message immediately, without its exit transition.
  static void dismiss() {
    _current?.remove();
    _current = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (Color background, IconData defaultIcon) = switch (kind) {
      AppSnackBarKind.success => (theme.palette.success, Icons.check_circle_rounded),
      AppSnackBarKind.error => (theme.colorScheme.error, Icons.error_outline_rounded),
      AppSnackBarKind.info => (theme.colorScheme.primary, Icons.info_outline_rounded),
    };

    return Material(
      color: background,
      elevation: 6,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
        child: Row(
          children: <Widget>[
            Icon(icon ?? defaultIcon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tracks one inserted entry so it can never be removed twice — a second
/// `OverlayEntry.remove()` throws, and both the timeout and a replacement can
/// race to remove the same message.
class _ActiveSnackBar {
  _ActiveSnackBar(this.entry);

  final OverlayEntry entry;
  bool _removed = false;

  void remove() {
    if (_removed) return;
    _removed = true;
    entry.remove();
  }
}

/// Positions the message, animates it in and out, and owns its lifetime.
class _SnackBarHost extends StatefulWidget {
  const _SnackBarHost({
    required this.duration,
    required this.onDismissed,
    required this.child,
  });

  final Duration duration;
  final VoidCallback onDismissed;
  final Widget child;

  @override
  State<_SnackBarHost> createState() => _SnackBarHostState();
}

class _SnackBarHostState extends State<_SnackBarHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 200),
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _hide);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _hide() async {
    _timer?.cancel();
    if (!mounted) return;

    // If the controller is disposed mid-reverse this future simply never
    // completes, which is the correct outcome: whoever disposed it has already
    // removed the entry.
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      // Spans the full width, so there is no leading/trailing side for RTL to
      // disagree about.
      left: 0,
      right: 0,
      child: SlideTransition(
        // Vertical only — nothing here mirrors.
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(_curve),
        child: FadeTransition(
          opacity: _curve,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
              child: Dismissible(
                key: const ValueKey<String>('app-snack-bar'),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismissed(),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
