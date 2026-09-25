import 'package:thaheen_task/core/utils/json_object.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_model.dart';

/// A titled group of lessons inside a course.
///
/// A section is allowed to be empty — the UI renders an explicit empty state
/// for it rather than hiding it, so a student never wonders where a chapter went.
class SectionModel {
  const SectionModel({
    required this.id,
    required this.title,
    required this.lessons,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) => SectionModel(
        id: json.readString('id'),
        title: json.readString('title'),
        // Absent or malformed `lessons` yields an empty section rather than an
        // error — the UI has a first-class empty state for that.
        lessons: <LessonModel>[
          for (final lesson in json.readObjectList('lessons'))
            LessonModel.fromJson(lesson),
        ],
      );

  final String id;
  final String title;
  final List<LessonModel> lessons;

  bool get isEmpty => lessons.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionModel &&
          other.id == id &&
          other.title == title &&
          _sameLessons(other.lessons, lessons);

  @override
  int get hashCode => Object.hash(id, title, Object.hashAll(lessons));

  @override
  String toString() => 'SectionModel($id, ${lessons.length} lessons)';
}

bool _sameLessons(List<LessonModel> a, List<LessonModel> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
