import 'package:thaheen_task/core/utils/json_object.dart';

/// Lesson id -> saved progress. The shape every rule below is computed against.
typedef ProgressByLesson = Map<String, LessonProgressModel>;

/// Reads a lesson's progress, treating "never opened" as a real value rather
/// than a null the caller has to keep re-checking.
extension ProgressLookup on ProgressByLesson {
  LessonProgressModel forLesson(String lessonId) =>
      this[lessonId] ?? LessonProgressModel.untouched(lessonId);
}

/// The student's watch state for one lesson — and the rules that govern it.
///
/// Two different "how far in" numbers are tracked deliberately, because they
/// answer two different questions:
///
/// * [positionSec] — *where do we resume?* It follows the playhead exactly,
///   including backwards seeks.
/// * [watchedSec] — *how much of this lesson has been reached?* It is a
///   high-water mark and never decreases, so scrubbing back to rewatch a tricky
///   explanation cannot un-complete a lesson the student already finished.
///
/// Persisted as a JSON string in a Hive `Box<String>` keyed by lesson id rather
/// than through a generated `TypeAdapter`. The trade-off is deliberate:
/// adapters buy a little speed and cost a `typeId` registry plus a bespoke
/// migration path for every field change. At this size a self-describing JSON
/// blob is easier to read, to version and to test — and [fromJson] tolerates
/// unknown or missing keys, so a payload written by an older build still loads
/// instead of throwing on startup.
class LessonProgressModel {
  const LessonProgressModel({
    required this.lessonId,
    this.positionSec = 0,
    this.watchedSec = 0,
    this.durationSec = 0,
    this.completed = false,
    this.updatedAtMs,
  });

  /// The state of a lesson the student has never opened.
  const LessonProgressModel.untouched(this.lessonId)
      : positionSec = 0,
        watchedSec = 0,
        durationSec = 0,
        completed = false,
        updatedAtMs = null;

  /// Rebuilds a record from storage.
  ///
  /// [fallbackLessonId] is the Hive key the payload was found under; it is used
  /// when the stored blob predates the `lessonId` field or has lost it.
  factory LessonProgressModel.fromJson(
    Map<String, dynamic> json, {
    required String fallbackLessonId,
  }) {
    final rawId = json['lessonId'];
    return LessonProgressModel(
      lessonId: rawId is String && rawId.isNotEmpty ? rawId : fallbackLessonId,
      positionSec: json.readInt('positionSec'),
      watchedSec: json.readInt('watchedSec'),
      durationSec: json.readInt('durationSec'),
      completed: json.readBool('completed'),
      updatedAtMs:
          json.containsKey('updatedAtMs') ? json.readInt('updatedAtMs') : null,
    );
  }

  /// A lesson counts as finished once this much of it has been reached.
  ///
  /// The single source of truth for the 90% rule — the player, the lesson list
  /// and the course progress bar all read it from here.
  static const double completionThreshold = 0.9;

  final String lessonId;

  /// Last known playhead position, in seconds. Drives resume-on-reopen.
  final int positionSec;

  /// Furthest point reached, in seconds. Monotonically non-decreasing.
  final int watchedSec;

  /// Duration as reported by the player, in seconds.
  ///
  /// Zero until the video has been initialised at least once; callers fall back
  /// to the catalogue's declared duration while it is unknown.
  final int durationSec;

  /// Sticky completion flag, persisted so the unlock rule survives a restart.
  final bool completed;

  /// Epoch milliseconds, kept primitive so the payload stays plain JSON.
  final int? updatedAtMs;

  DateTime? get updatedAt => updatedAtMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(updatedAtMs!);

  /// True once the student has opened the lesson at all.
  bool get hasStarted => watchedSec > 0 || positionSec > 0 || completed;

  /// Picks the most trustworthy duration available.
  ///
  /// The player's measurement beats the catalogue's declared number, which in
  /// turn beats nothing at all.
  int effectiveDuration(int declaredDurationSec) =>
      durationSec > 0 ? durationSec : declaredDurationSec;

  /// Fraction of the lesson reached, in `0.0..1.0`.
  ///
  /// Returns `0` while the duration is still unknown rather than dividing by
  /// zero; a completed lesson always reports a full `1.0` even if its stored
  /// duration is stale.
  double watchedRatio(int declaredDurationSec) {
    if (completed) return 1;
    final total = effectiveDuration(declaredDurationSec);
    if (total <= 0) return 0;
    return (watchedSec / total).clamp(0.0, 1.0);
  }

  /// **The 90% rule.** True when enough of the lesson has been reached to call
  /// it finished.
  ///
  /// Evaluated against [watchedSec], not [positionSec], so rewinding never
  /// undoes completion. A lesson with no known duration can never satisfy the
  /// rule — better to leave it in progress than to complete it on a guess.
  bool meetsCompletionThreshold(int declaredDurationSec) {
    final total = effectiveDuration(declaredDurationSec);
    if (total <= 0) return false;
    return watchedSec / total >= completionThreshold;
  }

  /// Folds a playback tick into this record, applying every rule at once.
  ///
  /// This is the only place progress advances, which is what keeps the rules
  /// impossible to apply inconsistently:
  ///
  /// * the resume point follows the playhead, forwards or backwards;
  /// * the watched high-water mark only ever rises;
  /// * a real duration from the player overwrites a stale or absent one;
  /// * completion latches on at the 90% threshold and never latches off.
  LessonProgressModel afterPlayback({
    required int positionSec,
    required int reportedDurationSec,
    required int declaredDurationSec,
    DateTime? now,
  }) {
    final safePosition = positionSec < 0 ? 0 : positionSec;
    final nextDuration =
        reportedDurationSec > 0 ? reportedDurationSec : durationSec;
    final nextWatched = safePosition > watchedSec ? safePosition : watchedSec;

    final candidate = copyWith(
      positionSec: safePosition,
      watchedSec: nextWatched,
      durationSec: nextDuration,
      updatedAt: now ?? DateTime.now(),
    );

    return candidate.completed
        ? candidate
        : candidate.copyWith(
            completed: candidate.meetsCompletionThreshold(declaredDurationSec),
          );
  }

  LessonProgressModel copyWith({
    int? positionSec,
    int? watchedSec,
    int? durationSec,
    bool? completed,
    DateTime? updatedAt,
  }) =>
      LessonProgressModel(
        lessonId: lessonId,
        positionSec: positionSec ?? this.positionSec,
        watchedSec: watchedSec ?? this.watchedSec,
        durationSec: durationSec ?? this.durationSec,
        completed: completed ?? this.completed,
        updatedAtMs: updatedAt?.millisecondsSinceEpoch ?? updatedAtMs,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lessonId': lessonId,
        'positionSec': positionSec,
        'watchedSec': watchedSec,
        'durationSec': durationSec,
        'completed': completed,
        if (updatedAtMs != null) 'updatedAtMs': updatedAtMs,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonProgressModel &&
          other.lessonId == lessonId &&
          other.positionSec == positionSec &&
          other.watchedSec == watchedSec &&
          other.durationSec == durationSec &&
          other.completed == completed &&
          other.updatedAtMs == updatedAtMs;

  @override
  int get hashCode => Object.hash(
        lessonId,
        positionSec,
        watchedSec,
        durationSec,
        completed,
        updatedAtMs,
      );

  @override
  String toString() => 'LessonProgressModel($lessonId, pos=$positionSec, '
      'watched=$watchedSec/$durationSec, completed=$completed)';
}
