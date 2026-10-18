import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/i18n/app_lang.dart';
import 'core/providers/app_preferences_providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/app_prefs.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final lang = ref.watch(languageProvider);

    // Remember the choices on this device.
    ref.listen<ThemeMode>(themeModeProvider, (_, m) {
      AppPrefs.saveThemeMode(m);
    });
    ref.listen<String>(languageProvider, (_, l) {
      AppPrefs.saveLanguage(l);
    });
    ref.listen<bool>(notificationsEnabledProvider, (_, on) {
      AppPrefs.saveNotifications(on);
    });

    // Resolve the active palette + language BEFORE any widget builds. Pages
    // read colours/strings through AppColors / tr(), so they follow these.
    final systemDark =
        ui.PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    final isDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => systemDark,
    };
    AppPalette.current = isDark ? AppPalette.dark : AppPalette.light;
    AppLang.code = lang == 'id' ? 'id' : 'en';
    Intl.defaultLocale = AppLang.code;

    // Watching the theme/language also rebuilds the router (see
    // appRouterProvider), which together with the key below rebuilds every
    // page from scratch so const widgets pick up the new colours and text.
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      key: ValueKey('app-${isDark ? 'dark' : 'light'}-${AppLang.code}'),
      title: 'Kaizen Home Spa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(AppLang.code),
      supportedLocales: const [Locale('en'), Locale('id')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // The UI is positioned to the Figma design, which breaks when the
        // system font size is set very large (text collides with absolutely
        // positioned siblings). Honor accessibility scaling up to 1.2×.
        final media = MediaQuery.of(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(
                media.textScaler.scale(1).clamp(1.0, 1.2),
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
