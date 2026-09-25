import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:thaheen_task/core/localization/app_locales.dart';

/// Guards the contract between the generated keys and the translation bundles.
///
/// `lib/generated/locale_keys.g.dart` is generated *from* `assets/translations/`,
/// so the two agree at the moment of generation — and silently drift the first
/// time someone edits a JSON file without re-running the generator. These tests
/// fail on that drift instead of letting a raw `courses.title` reach the screen.
void main() {
  const generatedKeys = 'lib/generated/locale_keys.g.dart';
  const pluralForms = {'zero', 'one', 'two', 'few', 'many', 'other'};

  late List<String> declaredKeys;
  late Map<String, Map<String, dynamic>> bundles;

  setUpAll(() {
    final source = File(generatedKeys).readAsStringSync();
    declaredKeys = RegExp(r"static const \w+ = '([^']+)';")
        .allMatches(source)
        .map((match) => match.group(1)!)
        .toList();

    bundles = <String, Map<String, dynamic>>{
      for (final locale in AppLocales.supported)
        locale.languageCode: jsonDecode(
          File('${AppLocales.translationsPath}/${locale.languageCode}.json')
              .readAsStringSync(),
        ) as Map<String, dynamic>,
    };
  });

  /// Walks a dot-path and returns the node it points at, or `null`.
  Object? resolve(Map<String, dynamic> bundle, String dotPath) {
    Object? node = bundle;
    for (final segment in dotPath.split('.')) {
      if (node is! Map<String, dynamic>) return null;
      node = node[segment];
    }
    return node;
  }

  test('the generated keys file is present and populated', () {
    expect(
      declaredKeys,
      isNotEmpty,
      reason: 'run: dart run easy_localization:generate '
          '-S assets/translations -O lib/generated -f keys -o locale_keys.g.dart',
    );
    expect(declaredKeys.toSet(), hasLength(declaredKeys.length),
        reason: 'duplicate generated keys');
  });

  for (final languageCode in <String>['ar', 'en']) {
    test('every generated key still resolves in $languageCode.json', () {
      final unresolved = <String>[
        for (final key in declaredKeys)
          if (resolve(bundles[languageCode]!, key) == null) key,
      ];
      expect(
        unresolved,
        isEmpty,
        reason: 'locale_keys.g.dart is stale for $languageCode.json — regenerate it',
      );
    });
  }

  test('Arabic is the fallback locale, so it defines every leaf', () {
    // Arabic-first: `en.json` may lag behind, `ar.json` may not.
    final arabicLeaves = <String>[];
    void walk(Map<String, dynamic> node, String prefix) {
      node.forEach((key, value) {
        final path = prefix.isEmpty ? key : '$prefix.$key';
        if (value is Map<String, dynamic> && !value.keys.any(pluralForms.contains)) {
          walk(value, path);
        } else {
          arabicLeaves.add(path);
        }
      });
    }

    walk(bundles['ar']!, '');
    expect(arabicLeaves, isNotEmpty);
    expect(
      arabicLeaves.where((path) => resolve(bundles['en']!, path) == null),
      isEmpty,
      reason: 'keys present in ar.json but absent from en.json',
    );
  });
}
