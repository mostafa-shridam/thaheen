/// What a lesson looks like to the student right now.
///
/// Derived, never stored: it combines the saved progress for a lesson with the
/// sequential-unlock rule, so it can only be computed with the whole course in
/// hand. See `CourseModel.statusOf`.
enum LessonStatus {
  /// Blocked because the preceding lesson is not completed yet.
  locked,

  /// Unlocked, never opened.
  notStarted,

  /// Unlocked, opened, below the completion threshold.
  inProgress,

  /// Watched past the completion threshold. Sticky — never reverts.
  completed;

  bool get isLocked => this == LessonStatus.locked;
  bool get isCompleted => this == LessonStatus.completed;
  bool get isPlayable => this != LessonStatus.locked;
}
