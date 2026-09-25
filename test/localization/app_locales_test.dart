import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_task/core/localization/app_locales.dart';

/// Guards the Arabic-first policy — and one load-bearing invariant.
///
/// `main.dart` skips `EasyLocalization.ensureInitialized()` so that nothing in
/// the app touches SharedPreferences. That is only safe while `startLocale` is
/// never null: a null one makes `easy_localization` fall through to a `late`
/// `_deviceLocale` that the skipped call would have initialised, which throws a
/// `LateInitializationError` on launch.
///
/// These tests are what keep that branch unreachable.
void main() {
  group('locale resolution', () {
    test('an unset language falls back to Arabic, never null', () {
      expect(AppLocales.fromLanguageCode(null), AppLocales.arabic);
    });

    test('an unrecognised language falls back to Arabic', () {
      // A device set to French must land on Arabic, not English.
      expect(AppLocales.fromLanguageCode('fr'), AppLocales.arabic);
      expect(AppLocales.fromLanguageCode(''), AppLocales.arabic);
    });

    test('saved languages round-trip', () {
      expect(AppLocales.fromLanguageCode('ar'), AppLocales.arabic);
      expect(AppLocales.fromLanguageCode('en'), AppLocales.english);
    });

    test('every resolvable locale is actually supported', () {
      for (final code in <String?>[null, '', 'ar', 'en', 'fr', 'zz']) {
        expect(
          AppLocales.supported,
          contains(AppLocales.fromLanguageCode(code)),
          reason: 'resolved an unsupported locale for "$code"',
        );
      }
    });
  });

  group('Arabic-first policy', () {
    test('the fallback locale is Arabic', () {
      expect(AppLocales.fallback, AppLocales.arabic);
    });

    test('Arabic is listed first, so it leads the language switcher', () {
      expect(AppLocales.supported.first, AppLocales.arabic);
    });

    test('direction is derived from the language', () {
      expect(AppLocales.isRtl(AppLocales.arabic), isTrue);
      expect(AppLocales.isRtl(AppLocales.english), isFalse);
    });
  });
}
