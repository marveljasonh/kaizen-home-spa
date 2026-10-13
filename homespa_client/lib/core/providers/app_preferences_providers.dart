import '../i18n/material_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_prefs.dart';

/// Appearance. Default: dark. Persisted by `App` whenever it changes.
final themeModeProvider = StateProvider<ThemeMode>(
  (ref) => AppPrefs.themeMode,
);

/// UI language code: 'en' (default) or 'id'. Persisted by `App`.
final languageProvider = StateProvider<String>((ref) => AppPrefs.language);

final notificationsEnabledProvider = StateProvider<bool>(
  (ref) => AppPrefs.notifications,
);
