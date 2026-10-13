import 'strings_id.dart';

/// Runtime language state + the `tr()` lookup.
///
/// English is the source language: every UI string in the code is written in
/// English and passed through [tr] (the app-wide [Text] wrapper in
/// `tr_text.dart` does this automatically). When the selected language is
/// Indonesian, [tr] looks the English text up in [kStringsId]; anything that is
/// missing from the dictionary is shown as-is, so a gap never breaks the UI.
///
/// Dynamic strings are supported through templates: a dictionary key that
/// contains `{}` matches any text of that shape, e.g.
/// `'Hello, {}': 'Halo, {}'` translates "Hello, Marvel" to "Halo, Marvel".
class AppLang {
  AppLang._();

  /// 'en' (default) or 'id'. Set by `App` before the widget tree builds.
  static String code = 'en';

  static bool get isId => code == 'id';

  static const supported = <String, String>{'en': 'English', 'id': 'Bahasa'};

  static String get label => supported[code] ?? 'English';
}

final RegExp _tokenSplit = RegExp(r'\{\}');
List<_Template>? _templates;

class _Template {
  final RegExp pattern;
  final String target;
  _Template(this.pattern, this.target);
}

List<_Template> _buildTemplates() {
  final out = <_Template>[];
  kStringsId.forEach((key, value) {
    if (!key.contains('{}')) return;
    final parts = key.split(_tokenSplit).map(RegExp.escape).toList();
    out.add(_Template(RegExp('^${parts.join('(.+?)')}\$', dotAll: true), value));
  });
  // Longer (more specific) templates first.
  out.sort((a, b) => b.pattern.pattern.length - a.pattern.pattern.length);
  return out;
}

/// Translates [text] (English) into the selected language.
String tr(String text) {
  if (AppLang.code != 'id' || text.isEmpty) return text;

  final exact = kStringsId[text];
  if (exact != null) return exact;

  // Keep surrounding whitespace, look up the trimmed core.
  final core = text.trim();
  if (core.isEmpty) return text;
  if (core.length != text.length) {
    final lead = text.substring(0, text.indexOf(core));
    final trail = text.substring(lead.length + core.length);
    final hit = kStringsId[core];
    if (hit != null) return '$lead$hit$trail';
    return '$lead${_trTemplate(core)}$trail';
  }
  return _trTemplate(core);
}

String _trTemplate(String text) {
  _templates ??= _buildTemplates();
  for (final t in _templates!) {
    final m = t.pattern.firstMatch(text);
    if (m == null) continue;
    var i = 1;
    return t.target.replaceAllMapped(_tokenSplit, (_) {
      final captured = i <= m.groupCount ? (m.group(i) ?? '') : '';
      i++;
      return tr(captured);
    });
  }
  return text;
}
