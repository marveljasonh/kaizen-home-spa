/// Use instead of `package:flutter/material.dart` in UI files:
/// everything from Material, except `Text`, which is the translating wrapper.
library;

export 'package:flutter/material.dart' hide Text;
export 'tr_text.dart' show Text;
export 'app_lang.dart' show tr, AppLang;
