import 'package:thaheen_task/core/error/failures.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Maps a layer-agnostic [FailureCode] onto the copy shown to the student.
///
/// This is the single seam where an error stops being a code and becomes
/// words, which is why it lives here and not in the data or domain layers that
/// raise the codes. The keys themselves are generated from the translation
/// bundles — see `lib/generated/locale_keys.g.dart`.
///
/// The `switch` is exhaustive over [FailureCode] with no `default`, so adding a
/// new failure code is a compile error until it has copy in both languages.
extension FailureTranslations on AppFailure {
  /// Headline key, e.g. "تعذّر تشغيل هذا الدرس".
  String get messageKey => switch (code) {
        FailureCode.catalogueMissing => LocaleKeys.errors_catalogueMissing,
        FailureCode.catalogueCorrupt => LocaleKeys.errors_catalogueCorrupt,
        FailureCode.storageUnavailable => LocaleKeys.errors_storageUnavailable,
        FailureCode.videoUnavailable => LocaleKeys.errors_videoUnavailable,
        FailureCode.unexpected => LocaleKeys.errors_unexpected,
      };

  /// Supporting line explaining what the student can expect.
  String get hintKey => switch (code) {
        FailureCode.catalogueMissing => LocaleKeys.errors_catalogueMissingHint,
        FailureCode.catalogueCorrupt => LocaleKeys.errors_catalogueCorruptHint,
        FailureCode.storageUnavailable => LocaleKeys.errors_storageUnavailableHint,
        FailureCode.videoUnavailable => LocaleKeys.errors_videoUnavailableHint,
        FailureCode.unexpected => LocaleKeys.errors_unexpectedHint,
      };
}
