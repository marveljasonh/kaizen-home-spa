import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A branch and the WhatsApp number clients can reach it on.
///
/// The data lives in `branches` (`phone`, `operating_hours`) and is edited by
/// the admin in the dashboard (Branches page) — nothing is hard-coded here.
class BranchContact {
  final String id;
  final String name;
  final String? address;
  final String phone; // as typed in the dashboard
  final String? operatingHours;

  const BranchContact({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.operatingHours,
  });

  /// Digits only, in international form without "+" (what wa.me expects):
  /// `0812-3456-7890` → `6281234567890`, `+62 812…` → `62812…`.
  String get whatsappNumber => normalizeWhatsappNumber(phone);

  /// Readable form, e.g. `+62 812-3456-7890`.
  String get displayPhone => formatWhatsappNumber(phone);

  factory BranchContact.fromRow(Map<String, dynamic> row) {
    String? clean(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return BranchContact(
      id: row['id'].toString(),
      name: clean(row['name']) ?? 'Kaizen Home Spa',
      address: clean(row['address']),
      phone: clean(row['phone']) ?? '',
      operatingHours: clean(row['operating_hours']),
    );
  }
}

/// Normalises an Indonesian phone number to digits with the 62 country code.
String normalizeWhatsappNumber(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('0')) return '62${digits.substring(1)}';
  if (digits.startsWith('62')) return digits;
  if (digits.startsWith('8')) return '62$digits'; // typed without the 0
  return digits; // another country code, leave as is
}

/// `6281234567890` → `+62 812-3456-7890` (groups of 4 after the first 3).
String formatWhatsappNumber(String raw) {
  final n = normalizeWhatsappNumber(raw);
  if (n.isEmpty) return raw;
  if (!n.startsWith('62') || n.length < 8) return '+$n';
  final local = n.substring(2);
  final parts = <String>[local.substring(0, 3)];
  var rest = local.substring(3);
  while (rest.isNotEmpty) {
    final take = rest.length > 4 ? 4 : rest.length;
    parts.add(rest.substring(0, take));
    rest = rest.substring(take);
  }
  return '+62 ${parts.join('-')}';
}

/// Active branches that have a phone number, A → Z.
final branchContactsProvider = FutureProvider.autoDispose<List<BranchContact>>((
  ref,
) async {
  try {
    final rows = await Supabase.instance.client
        .from('branches')
        .select()
        .eq('is_active', true)
        .order('name', ascending: true);

    return [
      for (final row in rows as List<dynamic>)
        BranchContact.fromRow(Map<String, dynamic>.from(row as Map)),
    ].where((b) => b.whatsappNumber.isNotEmpty).toList();
  } catch (e) {
    debugPrint('[Contact] branches ERROR: $e');
    rethrow;
  }
});
