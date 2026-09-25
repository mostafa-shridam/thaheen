import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:thaheen_task/core/responsive/app_breakpoints.dart';
import 'package:thaheen_task/core/router/app_router.dart';
import 'package:thaheen_task/core/settings/theme_mode_controller.dart';
import 'package:thaheen_task/core/theme/app_theme.dart';
import 'package:thaheen_task/generated/locale_keys.g.dart';

/// Root widget.
///
/// Three things are installed here, once, and nowhere else:
///
/// 1. **Localisation** — the delegates, supported locales and current locale all
///    come from `easy_localization`. Text direction is *derived* from the active
///    locale by `WidgetsApp`, so Arabic lays out RTL and English LTR without a
///    hand-placed `Directionality` anywhere in the tree. Forcing one would break
///    the language switch.
/// 2. **Responsive sizing** — `ResponsiveBreakpoints.builder` wraps the router's
///    child in `MaterialApp.builder`, above every feature widget and outside any
///    directionality concern, exactly as `docs/DESIGN_SYSTEM.md` requires.
/// 3. **Theme** — light and dark from [AppTheme], switched by the persisted
///    [ThemeModeController].
class ThaheenApp extends ConsumerWidget {
  const ThaheenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp.router(
      // Localised so the OS task switcher shows the Arabic name too.
      onGenerateTitle: (context) => LocaleKeys.app_name.tr(),
      debugShowCheckedModeBanner: false,

      routerConfig: ref.watch(appRouterProvider),

      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      builder: (context, child) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ResponsiveBreakpoints.builder(
          breakpoints: AppBreakpoints.all,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
