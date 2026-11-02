import '../i18n/material_i18n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local app preferences (appearance, language, notifications).
///
/// Defaults: dark mode, English, notifications on. [init] is awaited in
/// `main()` before `runApp`, so the providers can read synchronously.
class AppPrefs {
  AppPrefs._();

  static SharedPreferences? _prefs;

  static const _kTheme = 'pref_theme_mode';
  static const _kLang = 'pref_language';
  static const _kNotif = 'pref_notifications';
  static const _kBranch = 'pref_branch_id';

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null; // fall back to defaults; nothing is persisted
    }
  }

  static ThemeMode get themeMode {
    switch (_prefs?.getString(_kTheme)) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  static String get language => _prefs?.getString(_kLang) == 'id' ? 'id' : 'en';

  static bool get notifications => _prefs?.getBool(_kNotif) ?? true;

  static void saveThemeMode(ThemeMode mode) {
    _prefs?.setString(_kTheme, mode.name);
  }

  static void saveLanguage(String code) {
    _prefs?.setString(_kLang, code);
  }

  static void saveNotifications(bool on) {
    _prefs?.setBool(_kNotif, on);
  }

  /// Chosen branch id, or null for "nearest branch (auto)".
  static String? get branchId {
    final v = _prefs?.getString(_kBranch);
    return (v == null || v.isEmpty) ? null : v;
  }

  static void saveBranchId(String? id) {
    if (id == null) {
      _prefs?.remove(_kBranch);
    } else {
      _prefs?.setString(_kBranch, id);
    }
  }
}
