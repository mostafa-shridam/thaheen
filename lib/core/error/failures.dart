/// Machine-readable cause of a failure.
///
/// The domain and data layers never carry user-facing copy: they report a
/// [FailureCode], and the presentation layer maps that code to an Arabic (or
/// English) message. That keeps every translatable string in one place and
/// keeps the layers below `presentation/` free of localisation concerns.
enum FailureCode {
  /// `assets/data/courses.json` could not be read from the bundle at all.
  catalogueMissing,

  /// The catalogue was read but is not valid JSON, or is missing required fields.
  catalogueCorrupt,

  /// A Hive box could not be opened or written to.
  storageUnavailable,

  /// A lesson's bundled `.mp4` is missing, unreadable or refused by the decoder.
  videoUnavailable,

  /// Anything we did not anticipate. Always paired with a `debugDetail`.
  unexpected,
}

/// The single error type crossing layer boundaries.
///
/// Implements [Exception] so data sources can `throw` it and callers can catch
/// one concrete type; `debugDetail` is developer-facing only and is never shown
/// to a student.
class AppFailure implements Exception {
  const AppFailure(this.code, {this.debugDetail});

  /// Wraps an arbitrary caught error, preserving an [AppFailure] if that is
  /// what was already thrown.
  factory AppFailure.from(Object error, {FailureCode fallback = FailureCode.unexpected}) {
    if (error is AppFailure) return error;
    return AppFailure(fallback, debugDetail: error.toString());
  }

  final FailureCode code;
  final String? debugDetail;

  @override
  String toString() =>
      'AppFailure(${code.name}${debugDetail == null ? '' : ': $debugDetail'})';
}
