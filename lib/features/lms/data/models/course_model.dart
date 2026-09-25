import 'package:thaheen_task/core/utils/json_object.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_progress_model.dart';
import 'package:thaheen_task/features/lms/data/models/lesson_status.dart';
import 'package:thaheen_task/features/lms/data/models/section_model.dart';

/// A course: the unit a student buys and works through top to bottom.
///
/// Alongside its JSON shape this model owns the two course-level rules, because
/// both are questions only a whole course can answer — "is lesson N unlocked?"
/// needs lesson N-1, and "how far along am I?" needs every lesson. Keeping them
/// here means there is exactly one implementation of each, directly unit
/// testable without a widget or a provider in sight.
class CourseModel {
  const CourseModel({
    required this.id,
    required this.title,
    required this.instructor,
    required this.thumbnail,
    required this.sections,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        id: json.readString('id'),
        title: json.readString('title'),
        instructor: json.readString('instructor'),
        thumbnail: json.readString('thumbnail'),
        sections: <SectionModel>[
          for (final section in json.readObjectList('sections'))
            SectionModel.fromJson(section),
        ],
      );

  final String id;
  final String title;
  final String instructor;

  /// Bundled asset path, e.g. `assets/images/anatomy.png`.
  final String thumbnail;

  final List<SectionModel> sections;

  // --- Structure ----------------------------------------------------------

  /// Every lesson flattened into the exact order a student walks them:
  /// section by section, lesson by lesson.
  ///
  /// This ordering *is* the contract the sequential-unlock rule is defined
  /// over, which is why it lives here rather than being re-derived per call site.
  List<LessonModel> get orderedLessons => <LessonModel>[
        for (final section in sections) ...section.lessons,
      ];

  int get lessonCount => orderedLessons.length;

  /// False when the course has no sections at all, or only empty ones.
  bool get hasLessons => sections.any((section) => section.lessons.isNotEmpty);

  /// Position of a lesson in [orderedLessons], or `-1` if it is not in this course.
  int indexOfLesson(String lessonId) =>
      orderedLessons.indexWhere((lesson) => lesson.id == lessonId);

  LessonModel? lessonById(String lessonId) {
    for (final lesson in orderedLessons) {
      if (lesson.id == lessonId) return lesson;
    }
    return null;
  }

  // --- Rules --------------------------------------------------------------

  /// **The sequential-unlock rule.** Lesson `index` is open only when the
  /// lesson before it is completed.
  ///
  /// The first lesson is always open — otherwise a brand-new course would be
  /// impossible to start. An out-of-range index is treated as locked rather
  /// than throwing, so a stale deep link degrades into a friendly message.
  bool isLessonUnlockedAt(int index, ProgressByLesson progress) {
    final lessons = orderedLessons;
    if (index < 0 || index >= lessons.length) return false;
    if (index == 0) return true;

    final previous = lessons[index - 1];
    return progress.forLesson(previous.id).completed;
  }

  bool isLessonUnlocked(String lessonId, ProgressByLesson progress) =>
      isLessonUnlockedAt(indexOfLesson(lessonId), progress);

  /// The lesson a locked tile should point at: the one that must be finished
  /// first. `null` when [lessonId] is unknown or is the opening lesson.
  LessonModel? blockingLessonFor(String lessonId) {
    final index = indexOfLesson(lessonId);
    if (index <= 0) return null;
    return orderedLessons[index - 1];
  }

  /// Combines stored progress with the unlock rule into the badge a lesson tile
  /// shows: locked / not started / in progress / completed.
  LessonStatus statusOfAt(int index, ProgressByLesson progress) {
    final lessons = orderedLessons;
    if (index < 0 || index >= lessons.length) return LessonStatus.locked;

    final lesson = lessons[index];
    final saved = progress.forLesson(lesson.id);

    // Completion outranks locking: a lesson already finished never regresses to
    // locked, whatever happened to the lessons around it.
    if (saved.completed) return LessonStatus.completed;
    if (!isLessonUnlockedAt(index, progress)) return LessonStatus.locked;
    return saved.hasStarted ? LessonStatus.inProgress : LessonStatus.notStarted;
  }

  LessonStatus statusOf(String lessonId, ProgressByLesson progress) =>
      statusOfAt(indexOfLesson(lessonId), progress);

  int completedLessonCount(ProgressByLesson progress) => orderedLessons
      .where((lesson) => progress.forLesson(lesson.id).completed)
      .length;

  /// **The progress rule.** Share of the course completed, in `0.0..1.0`.
  ///
  /// Counted in whole lessons rather than watched seconds: the student-facing
  /// promise is "4 of 5 lessons done", and a part-watched lesson that has not
  /// crossed the 90% line has not moved the course forward. An empty course is
  /// `0`, never a division by zero.
  double progressRatio(ProgressByLesson progress) {
    final total = lessonCount;
    if (total == 0) return 0;
    return completedLessonCount(progress) / total;
  }

  /// Progress as the whole percent shown on the card.
  ///
  /// Rounded *down*, so the UI never claims 100% while a lesson is still
  /// outstanding — the only way to see 100 is to have finished everything.
  int progressPercent(ProgressByLesson progress) =>
      (progressRatio(progress) * 100).floor();

  bool isCompleted(ProgressByLesson progress) =>
      hasLessons && completedLessonCount(progress) == lessonCount;

  /// The next lesson after [lessonId], or `null` at the end of the course.
  ///
  /// Returns it regardless of lock state; the caller decides whether to offer
  /// it or explain why it is still closed — which is what lets the player show
  /// a disabled "next lesson" button with a reason instead of hiding it.
  LessonModel? lessonAfter(String lessonId) {
    final index = indexOfLesson(lessonId);
    if (index < 0 || index + 1 >= lessonCount) return null;
    return orderedLessons[index + 1];
  }

  /// Where "continue watching" should drop the student.
  ///
  /// The first lesson that is unlocked and unfinished — started or not. Returns
  /// `null` when the course is finished or has no lessons, so the caller can
  /// fall back to a plain "start course".
  LessonModel? resumeLesson(ProgressByLesson progress) {
    final lessons = orderedLessons;
    for (var index = 0; index < lessons.length; index++) {
      final status = statusOfAt(index, progress);
      if (status == LessonStatus.inProgress || status == LessonStatus.notStarted) {
        return lessons[index];
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseModel &&
          other.id == id &&
          other.title == title &&
          other.instructor == instructor &&
          other.thumbnail == thumbnail &&
          _sameSections(other.sections, sections);

  @override
  int get hashCode =>
      Object.hash(id, title, instructor, thumbnail, Object.hashAll(sections));

  @override
  String toString() => 'CourseModel($id, ${sections.length} sections)';
}

bool _sameSections(List<SectionModel> a, List<SectionModel> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
