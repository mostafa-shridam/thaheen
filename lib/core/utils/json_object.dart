import 'package:thaheen_task/core/error/failures.dart';

/// Defensive readers for the bundled catalogue JSON.
///
/// The catalogue ships inside the app, so in principle it is always valid — but
/// a truncated download, a bad merge or a hand-edit must still surface as a
/// friendly error card rather than a red screen. Every read below is therefore
/// explicit about what it expects and what it does when the value is wrong.
///
/// The rule of thumb: a missing *identity* field (id, title, video path) makes
/// the record meaningless and throws; a missing *descriptive* field falls back
/// to a harmless default so one bad number cannot take down the whole screen.
extension JsonObject on Map<String, dynamic> {
  /// Reads a non-empty string, or throws [FailureCode.catalogueCorrupt].
  String readString(String key) {
    final value = this[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    throw AppFailure(
      FailureCode.catalogueCorrupt,
      debugDetail: 'expected a non-empty string at "$key", got ${value.runtimeType}',
    );
  }

  /// Reads an integer, coercing `num` and numeric strings, else [fallback].
  ///
  /// Negative values are clamped to zero: a negative duration or position is
  /// never meaningful and would otherwise poison the progress maths.
  int readInt(String key, {int fallback = 0}) {
    final value = this[key];
    final parsed = switch (value) {
      final int v => v,
      final num v => v.round(),
      final String v => int.tryParse(v.trim()) ?? double.tryParse(v.trim())?.round(),
      _ => null,
    };
    if (parsed == null) return fallback;
    return parsed < 0 ? 0 : parsed;
  }

  /// Reads a boolean, coercing the `'true'`/`'false'` strings, else [fallback].
  bool readBool(String key, {bool fallback = false}) {
    final value = this[key];
    return switch (value) {
      final bool v => v,
      'true' => true,
      'false' => false,
      _ => fallback,
    };
  }

  /// Reads a list of JSON objects, silently dropping non-object entries.
  ///
  /// Returns an empty list when the key is absent, which is what lets the UI
  /// render a genuine "no lessons yet" empty state instead of failing.
  List<Map<String, dynamic>> readObjectList(String key) {
    final value = this[key];
    if (value is! List) return const <Map<String, dynamic>>[];
    return <Map<String, dynamic>>[
      for (final item in value)
        if (item is Map<String, dynamic>) item,
    ];
  }
}
