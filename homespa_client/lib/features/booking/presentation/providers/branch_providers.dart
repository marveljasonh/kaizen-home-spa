import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/storage/app_prefs.dart';

/// A Kaizen branch as served by GET /branches (active branches only).
class Branch {
  final String id;
  final String name;
  final String? area;
  final String? city;
  final String? serviceAreas; // admin-edited "Areas We Serve", one per line
  final double? lat;
  final double? lng;

  const Branch({
    required this.id,
    required this.name,
    this.area,
    this.city,
    this.serviceAreas,
    this.lat,
    this.lng,
  });

  factory Branch.fromRow(Map<String, dynamic> row) => Branch(
    id: row['id'].toString(),
    name: (row['name'] as String?) ?? 'Kaizen',
    area: row['area'] as String?,
    city: row['city'] as String?,
    serviceAreas: row['serviceAreas'] as String?,
    lat: (row['lat'] as num?)?.toDouble(),
    lng: (row['lng'] as num?)?.toDouble(),
  );

  /// "Areas We Serve" as a clean list (split on newlines/commas, "> " trimmed).
  List<String> get serviceAreaList => [
    for (final part in (serviceAreas ?? '').split(RegExp(r'[\n,]')))
      if (part.replaceFirst(RegExp(r'^[>\-\s]+'), '').trim().isNotEmpty)
        part.replaceFirst(RegExp(r'^[>\-\s]+'), '').trim(),
  ];

  /// "Area" when it adds information beyond the name, else city, else null.
  String? get subtitle {
    final a = area?.trim();
    if (a != null && a.isNotEmpty && a != name) return a;
    final c = city?.trim();
    if (c != null && c.isNotEmpty && c != name) return c;
    return null;
  }
}

/// Active branches, as shown in the "Choose Your Branch" sheet. A → Z.
final branchesProvider = FutureProvider.autoDispose<List<Branch>>((ref) async {
  final json = await apiClient.get('/branches') as Map<String, dynamic>;
  final branches = [
    for (final row in (json['branches'] as List).cast<Map<String, dynamic>>())
      Branch.fromRow(row),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return branches;
});

/// The customer's chosen branch id, or null for "nearest branch (auto)" —
/// the pre-existing behavior where the platform picks the branch closest to
/// the booking address. Persisted on the device.
class SelectedBranchNotifier extends StateNotifier<String?> {
  SelectedBranchNotifier() : super(AppPrefs.branchId);

  void select(String? branchId) {
    state = branchId;
    AppPrefs.saveBranchId(branchId);
  }
}

final selectedBranchIdProvider =
    StateNotifierProvider<SelectedBranchNotifier, String?>(
      (ref) => SelectedBranchNotifier(),
    );

/// The chosen [Branch] object, or null when on "nearest (auto)" or while the
/// branch list is still loading. If a stored id no longer exists (branch
/// deactivated), this is also null and bookings fall back to auto.
final selectedBranchProvider = Provider.autoDispose<Branch?>((ref) {
  final id = ref.watch(selectedBranchIdProvider);
  if (id == null) return null;
  final branches = ref.watch(branchesProvider).valueOrNull;
  if (branches == null) return null;
  for (final b in branches) {
    if (b.id == id) return b;
  }
  return null;
});
