import 'package:flutter/material.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/widgets/app_skeleton_box.dart';

/// Skeleton mirroring the real card layout, so the swap to content does not
/// shift the page.
class CoursesSkeleton extends StatelessWidget {
  const CoursesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = AppBreakpoints.pagePadding(context);
    return ListView.separated(
      padding: EdgeInsetsDirectional.fromSTEB(padding, 8, padding, 24),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AppSkeletonBox(height: double.infinity, radius: 12),
          ),
          SizedBox(height: 12),
          AppSkeletonBox(width: 220, height: 18),
          SizedBox(height: 8),
          AppSkeletonBox(width: 140, height: 12),
          SizedBox(height: 10),
          AppSkeletonBox(width: 90, height: 24, radius: 10),
          SizedBox(height: 14),
          AppSkeletonBox(height: 6, radius: 999),
        ],
      ),
    );
  }
}
