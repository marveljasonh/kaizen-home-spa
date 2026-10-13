import 'strings_id_a.dart';
import 'strings_id_b.dart';
import 'strings_id_c.dart';
import 'strings_id_core.dart';
import 'strings_id_d.dart';
import 'strings_id_e.dart';
import 'strings_id_f.dart';
import 'strings_id_g.dart';
import 'strings_id_h.dart';

/// English → Indonesian dictionary. Keys are the exact English UI strings.
/// A key containing `{}` is a template (see `AppLang`): `{}` matches any text
/// and is copied (and translated) into the same position of the value.
///
/// The entries are split per feature group to keep the files manageable.
final Map<String, String> kStringsId = {
  ...kStringsIdCore,
  ...kStringsIdA,
  ...kStringsIdB,
  ...kStringsIdC,
  ...kStringsIdD,
  ...kStringsIdE,
  ...kStringsIdF,
  ...kStringsIdG,
  ...kStringsIdH,
};
