import 'package:flutter/material.dart';

/// The app's only bottom sheet.
///
/// Owns the chrome every sheet needs and none of them should re-decide: the
/// drag handle, the safe-area inset, the directional padding and the title
/// style. A caller supplies a title and its content.
///
/// [show] is the matching presentation helper, so the `showModalBottomSheet`
/// options — which must stay identical across sheets for them to feel like one
/// component — live here rather than at each call site.
class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.title, required this.children});

  final String title;

  /// Sheet content, laid out in a `Column`.
  final List<Widget> children;

  /// Presents [child] with the app's standard sheet options.
  ///
  /// Returns whatever the sheet pops, so a picker can resolve to its selection.
  static Future<T?> show<T>(BuildContext context, {required Widget child}) =>
      showModalBottomSheet<T>(
        context: context,
        showDragHandle: true,
        // Tall content (a long speed list on a short phone) scrolls instead of
        // being clipped.
        isScrollControlled: true,
        builder: (context) => child,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        // Directional, so the sheet mirrors correctly in Arabic.
        padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 20),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// A group heading inside an [AppSheet].
///
/// Separate from the sheet itself because a sheet may have none, one or several.
class AppSheetSection extends StatelessWidget {
  const AppSheetSection({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
