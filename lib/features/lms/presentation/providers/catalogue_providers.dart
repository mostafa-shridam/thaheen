import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:thaheen_task/features/lms/data/datasources/course_asset_data_source.dart';
import 'package:thaheen_task/features/lms/data/models/course_model.dart';

part 'catalogue_providers.g.dart';

/// Wiring for the course catalogue.
///
/// These providers are the composition root of the data layer. They are
/// `keepAlive` because the catalogue is a bundled asset that cannot change
/// while the app runs — re-reading and re-parsing it on every navigation would
/// be pure waste.
///
/// Tests override [courseAssetDataSourceProvider] rather than reaching for
/// `rootBundle`.
@Riverpod(keepAlive: true)
CourseAssetDataSource courseAssetDataSource(Ref ref) =>
    const CourseAssetDataSource();

/// Every course in the catalogue, parsed once per app session.
@Riverpod(keepAlive: true)
Future<List<CourseModel>> courseCatalogue(Ref ref) =>
    ref.watch(courseAssetDataSourceProvider).readCourses();

/// A single course by id, or `null` when the id is not in the catalogue.
///
/// Watching this instead of filtering inside a widget keeps the lookup out of
/// `build()` and lets the details screen rebuild only when *its* course changes.
@Riverpod(keepAlive: true)
Future<CourseModel?> courseById(Ref ref, String courseId) async {
  final courses = await ref.watch(courseCatalogueProvider.future);
  for (final course in courses) {
    if (course.id == courseId) return course;
  }
  return null;
}
