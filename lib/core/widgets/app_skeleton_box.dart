import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';
import 'package:thaheen_task/core/widgets/app_container.dart';

/// A softly pulsing placeholder block used to build skeleton loaders.
///
/// Hand-rolled rather than pulled from a shimmer package: one `AnimationController`
/// and an opacity tween is all a skeleton needs, and it keeps the offline bundle
/// one dependency lighter.
class AppSkeletonBox extends StatefulWidget {
  const AppSkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<AppSkeletonBox> createState() => _AppSkeletonBoxState();
}

class _AppSkeletonBoxState extends State<AppSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).palette.border;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: AppContainer(
        color: base,
        radius: widget.radius,
        width: widget.width,
        height: widget.height,
      ),
    );
  }
}
