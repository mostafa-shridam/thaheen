import 'dart:ui' show Locale;

/// Locale policy for the app.
///
/// Thaheen is Arabic-first in the strong sense: Arabic is both the startup
/// locale *and* the fallback, so a device set to any unsupported language still
/// lands on Arabic rather than English.
abstract final class AppLocales {
  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');

  /// Order matters: it is the order the language switcher renders.
  static const List<Locale> supported = <Locale>[arabic, english];

  /// Used for both `startLocale` and `fallbackLocale`.
  static const Locale fallback = arabic;

  static const String translationsPath = 'assets/translations';

  /// True when [locale] should lay out right-to-left.
  static bool isRtl(Locale locale) => locale.languageCode == 'ar';

  /// Resolves a persisted language code back to a supported locale,
  /// defaulting to Arabic for anything unrecognised.
  static Locale fromLanguageCode(String? code) => switch (code) {
        'en' => english,
        'ar' => arabic,
        _ => fallback,
      };
}
