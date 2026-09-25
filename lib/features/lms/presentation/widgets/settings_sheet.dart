import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thaheen_task/core/localization/app_locales.dart';
import 'package:thaheen_task/core/settings/settings_store.dart';
import 'package:thaheen_task/core/settings/theme_mode_controller.dart';
import 'package:thaheen_task/core/theme/app_colors.dart';
import 'package:thaheen_task/core/widgets/app_sheet.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Language and appearance settings.
///
/// Switching the language is the one action in the app that deliberately writes
/// to two places: `easy_localization` owns the *live* locale (so the tree
/// rebuilds and the layout flips direction immediately), and [SettingsStore]
/// owns the *persisted* one. Keeping `saveLocale: false` means Hive stays the
/// only storage engine — see `docs/ARCHITECTURE.md`.
class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) =>
      AppSheet.show<void>(context, child: const SettingsSheet());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = context.locale;
    final themeMode = ref.watch(themeModeControllerProvider);

    return AppSheet(
      title: LocaleKeys.settings_title.tr(),
      
      children: <Widget>[
        AppSheetSection(
          label: LocaleKeys.settings_language.tr(),
          child: _ChoiceRow<Locale>(
            options: <_Choice<Locale>>[
              _Choice<Locale>(
                value: AppLocales.arabic,
                label: LocaleKeys.settings_languageArabic.tr(),
              ),
              _Choice<Locale>(
                value: AppLocales.english,
                label: LocaleKeys.settings_languageEnglish.tr(),
              ),
            ],
            selected: currentLocale,
            onSelected: (locale) async {
              await context.setLocale(locale);
              await SettingsStore.writeLocale(locale);
            },
          ),
        ),
        const SizedBox(height: 22),
        AppSheetSection(
          label: LocaleKeys.settings_theme.tr(),
          child: _ChoiceRow<ThemeMode>(
            options: <_Choice<ThemeMode>>[
              _Choice<ThemeMode>(
                value: ThemeMode.system,
                label: LocaleKeys.settings_themeSystem.tr(),
              ),
              _Choice<ThemeMode>(
                value: ThemeMode.light,
                label: LocaleKeys.settings_themeLight.tr(),
              ),
              _Choice<ThemeMode>(
                value: ThemeMode.dark,
                label: LocaleKeys.settings_themeDark.tr(),
              ),
            ],
            selected: themeMode,
            onSelected: (mode) =>
                ref.read(themeModeControllerProvider.notifier).setMode(mode),
          ),
        ),
      ],
    );
  }
}

class _Choice<T> {
  const _Choice({required this.value, required this.label});

  final T value;
  final String label;
}

/// A row of mutually exclusive chips.
///
/// `Wrap` rather than `Row` so three long labels still fit on a narrow phone in
/// either language instead of overflowing.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_Choice<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final option in options)
          ChoiceChip(
            label: Text(option.label),
            selected: option.value == selected,
            onSelected: (_) => onSelected(option.value),
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: option.value == selected
                  ? theme.colorScheme.onPrimary
                  : theme.palette.textSecondary,
            ),
            selectedColor: theme.colorScheme.primary,
            showCheckmark: false,
            side: BorderSide(color: theme.palette.border),
          ),
      ],
    );
  }
}
