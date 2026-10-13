import '../i18n/material_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_prefs.dart';

/// Appearance is fixed to the dark "luxury spa" look (client decision,
/// 2026-10-13): the light palette stays in the codebase but no UI sets this
/// to anything other than dark.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// UI language code: 'en' (default) or 'id'. Persisted by `App`.
final languageProvider = StateProvider<String>((ref) => AppPrefs.language);

final notificationsEnabledProvider = StateProvider<bool>(
  (ref) => AppPrefs.notifications,
);
