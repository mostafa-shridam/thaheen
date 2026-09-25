import 'package:flutter/material.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/widgets/app_skeleton_box.dart';

/// Loading placeholder shaped like the details screen it replaces.
class CourseDetailsSkeleton extends StatelessWidget {
  const CourseDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = AppBreakpoints.pagePadding(context);
    return ListView(
      padding: EdgeInsetsDirectional.fromSTEB(padding, 8, padding, 24),
      children: const <Widget>[
        AspectRatio(
          aspectRatio: 16 / 9,
          child: AppSkeletonBox(height: double.infinity, radius: 12),
        ),
        SizedBox(height: 16),
        AppSkeletonBox(width: 240, height: 20),
        SizedBox(height: 10),
        AppSkeletonBox(width: 150, height: 12),
        SizedBox(height: 20),
        AppSkeletonBox(height: 48, radius: 10),
        SizedBox(height: 28),
        AppSkeletonBox(width: 120),
        SizedBox(height: 16),
        AppSkeletonBox(height: 62, radius: 12),
        SizedBox(height: 8),
        AppSkeletonBox(height: 62, radius: 12),
        SizedBox(height: 8),
        AppSkeletonBox(height: 62, radius: 12),
      ],
    );
  }
}
