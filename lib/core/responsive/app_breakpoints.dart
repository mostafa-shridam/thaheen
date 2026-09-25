import 'package:flutter/widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// The single definition of the app's breakpoints.
///
/// Declared once here and installed once in `MaterialApp.builder`. Feature
/// widgets read the active breakpoint through
/// `ResponsiveBreakpoints.of(context)` or pick values with `ResponsiveValue<T>`
/// — they never do `MediaQuery` arithmetic of their own.
abstract final class AppBreakpoints {
  static const List<Breakpoint> all = <Breakpoint>[
    Breakpoint(start: 0, end: 450, name: MOBILE),
    Breakpoint(start: 451, end: 800, name: TABLET),
    Breakpoint(start: 801, end: 1920, name: DESKTOP),
  ];

  /// Content stops growing past this width on large shells, so Arabic text
  /// never stretches into unreadably long lines on a desktop window.
  static const double contentMaxWidth = 840;

  /// Horizontal page padding, widened past the mobile breakpoint.
  ///
  /// Lives here rather than in each page so the two screens cannot drift
  /// apart, and it is read through `ResponsiveValue` rather than `MediaQuery`
  /// arithmetic, per the responsive rules in `docs/DESIGN_SYSTEM.md`.
  static double pagePadding(BuildContext context) => ResponsiveValue<double>(
        context,
        defaultValue: 16,
        conditionalValues: const <Condition<double>>[
          Condition<double>.largerThan(name: MOBILE, value: 24),
        ],
      ).value;
}
