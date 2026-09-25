import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:thaheen_task/core/error/failures.dart';
import 'package:thaheen_task/core/utils/json_object.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';

/// Reads the bundled course catalogue.
///
/// This is the app's only source of course data: there is no network layer, by
/// design. The [AssetBundle] is injectable so tests can feed a fixture (or a
/// deliberately corrupt one) without touching `rootBundle`.
class CourseAssetDataSource {
  const CourseAssetDataSource({this.bundle});

  static const String assetPath = 'assets/data/courses.json';

  /// Overridden in tests; `null` means the real application bundle.
  final AssetBundle? bundle;

  AssetBundle get _assets => bundle ?? rootBundle;

  Future<List<CourseModel>> readCourses() async {
    final String raw;
    try {
      raw = await _assets.loadString(assetPath);
    } on Object catch (error) {
      throw AppFailure(
        FailureCode.catalogueMissing,
        debugDetail: 'could not load $assetPath: $error',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw AppFailure(
        FailureCode.catalogueCorrupt,
        debugDetail: 'invalid JSON in $assetPath: ${error.message}',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const AppFailure(
        FailureCode.catalogueCorrupt,
        debugDetail: 'catalogue root must be a JSON object',
      );
    }

    try {
      return <CourseModel>[
        for (final course in decoded.readObjectList('courses'))
          CourseModel.fromJson(course),
      ];
    } on Object catch (error) {
      // Field-level parsing already throws typed failures; this catches
      // anything unanticipated so no raw exception can reach a widget.
      throw AppFailure.from(error, fallback: FailureCode.catalogueCorrupt);
    }
  }
}
