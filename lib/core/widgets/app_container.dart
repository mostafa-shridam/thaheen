import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_theme.dart';

/// The shapes a surface in this app is allowed to take.
///
/// A closed set on purpose: three shapes cover every card, chip and badge in
/// Thaheen, and keeping it closed is what stops a fourth radius appearing by
/// accident.
enum AppSurfaceShape {
  /// Cards and list tiles — `AppTheme.cardRadius`.
  rounded,

  /// Chips and pills — fully rounded ends.
  pill,

  /// Status badges and icon bubbles.
  circle,
}

/// The app's only decorated surface.
///
/// Every card, chip, badge and tappable block goes through this widget. Before
/// it existed the same `Container(decoration: BoxDecoration(...))` was written
/// out in six places, each free to pick its own radius — which is exactly how a
/// design system drifts.
///
/// Two things it does that a bare `Container` does not:
///
/// * **Ink stays inside the shape.** When [onTap] is given it builds
///   `Material` + `InkWell` with the *same* border radius as the decoration, so
///   a ripple can never spill past a rounded corner.
/// * **Colours default to the theme.** [color] falls back to the surface colour
///   and [borderColor] to the palette border, so callers name them only when
///   they genuinely differ.
class AppContainer extends StatelessWidget {
  const AppContainer({
    super.key,
    this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.shape = AppSurfaceShape.rounded,
    this.radius,
    this.onTap,
    this.width,
    this.height,
    this.alignment,
  });

  /// Optional: a surface may be purely decorative, such as the accent bar
  /// beside a section title.
  final Widget? child;

  /// Directional by design — a plain `EdgeInsets` would not mirror in Arabic.
  final EdgeInsetsDirectional? padding;

  /// Defaults to `colorScheme.surface`.
  final Color? color;

  /// When null, no border is drawn. Pass a colour to outline the surface.
  final Color? borderColor;

  final AppSurfaceShape shape;

  /// Overrides the radius for [AppSurfaceShape.rounded] only.
  final double? radius;

  /// When set, the surface becomes tappable and gets a correctly clipped ripple.
  final VoidCallback? onTap;

  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  BorderRadius? _borderRadius() => switch (shape) {
        AppSurfaceShape.circle => null,
        AppSurfaceShape.pill => BorderRadius.circular(999),
        AppSurfaceShape.rounded =>
          BorderRadius.circular(radius ?? AppTheme.cardRadius),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = color ?? theme.colorScheme.surface;
    final borderRadius = _borderRadius();

    return Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: onTap == null ? padding : null,
      decoration: BoxDecoration(
        color: background,
        borderRadius: borderRadius,
        shape: shape == AppSurfaceShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: onTap == null
          ? child
          // The ink layer must sit inside the decoration but outside the
          // padding, so the ripple covers the whole surface.
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                customBorder: shape == AppSurfaceShape.circle
                    ? const CircleBorder()
                    : RoundedRectangleBorder(borderRadius: borderRadius!),
                child: Padding(
                  padding: padding ?? EdgeInsetsDirectional.zero,
                  child: child,
                ),
              ),
            ),
    );
  }
}
