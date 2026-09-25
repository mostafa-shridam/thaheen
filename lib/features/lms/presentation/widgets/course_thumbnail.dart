import 'package:flutter/material.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';

/// A course's bundled cover image, with a graceful stand-in when it is missing.
///
/// `Image.asset` throws during paint if the asset is absent, which would put a
/// red box on screen. The `errorBuilder` turns that into a neutral placeholder
/// instead — the same "never fail loudly" rule the rest of the app follows.
class CourseThumbnail extends StatelessWidget {
  const CourseThumbnail({
    super.key,
    required this.assetPath,
    this.aspectRatio = 16 / 9,
  });

  final String assetPath;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).palette;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: palette.border,
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: palette.locked,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
