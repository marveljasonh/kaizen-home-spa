import '../../../../core/api/api_client.dart';
import '../../domain/entities/addon.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/treatment_category.dart';
import '../../domain/entities/treatment_duration.dart';

abstract interface class TreatmentsRemoteDataSource {
  Future<List<TreatmentCategory>> getCategories();

  /// [query] matches name or description (case-insensitive substring).
  Future<List<Treatment>> getTreatments({String? categoryId, String? query});
  Future<Treatment> getTreatmentDetail(String id);
  Future<List<Addon>> getAddons();
}

/// Backed by GET /catalog — one payload with categories, services (the app's
/// "treatments"), packages (duration/price variants), and add-ons. Fetched
/// once and walked locally; filtering/search happen client-side.
class TreatmentsRemoteDataSourceImpl implements TreatmentsRemoteDataSource {
  final ApiClient _api;
  TreatmentsRemoteDataSourceImpl(this._api);

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _catalog() async {
    final cached = _cache;
    if (cached != null) return cached;
    final json = await _api.get('/catalog') as Map<String, dynamic>;
    _cache = json;
    return json;
  }

  @override
  Future<List<TreatmentCategory>> getCategories() async {
    final json = await _catalog();
    return (json['categories'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (c) => TreatmentCategory(
            id: c['id'] as String,
            name: c['name'] as String,
          ),
        )
        .toList();
  }

  List<Treatment> _parseTreatments(Map<String, dynamic> json) {
    final categoryNameById = {
      for (final c in (json['categories'] as List).cast<Map<String, dynamic>>())
        c['id'] as String: c['name'] as String,
    };
    final packagesByServiceId = <String, List<Map<String, dynamic>>>{};
    for (final p in (json['packages'] as List).cast<Map<String, dynamic>>()) {
      packagesByServiceId.putIfAbsent(p['serviceId'] as String, () => []).add(p);
    }

    return (json['services'] as List).cast<Map<String, dynamic>>().map((s) {
      final serviceId = s['id'] as String;
      // Sorted by durationMin by the API; the shortest variant is the default.
      final packages = packagesByServiceId[serviceId] ?? const [];
      final durations = <TreatmentDuration>[
        for (var i = 0; i < packages.length; i++)
          TreatmentDuration(
            id: packages[i]['id'] as String,
            treatmentId: serviceId,
            durationMinutes: (packages[i]['durationMin'] as num).toInt(),
            price: (packages[i]['priceIdr'] as num).toDouble(),
            isDefault: i == 0,
          ),
      ];
      final photoUrl = packages
          .map((p) => p['photoUrl'] as String?)
          .firstWhere((u) => u != null && u.isNotEmpty, orElse: () => null);
      return Treatment(
        id: serviceId,
        name: s['name'] as String,
        description: (s['description'] as String?) ?? '',
        categoryId: s['categoryId'] as String,
        categoryName: categoryNameById[s['categoryId']] ?? '',
        imageUrl: photoUrl,
        basePrice: durations.isEmpty
            ? 0
            : durations.map((d) => d.price).reduce((a, b) => a < b ? a : b),
        rating: 0,
        reviewCount: 0,
        durations: durations,
      );
    }).toList();
  }

  @override
  Future<List<Treatment>> getTreatments({
    String? categoryId,
    String? query,
  }) async {
    final all = _parseTreatments(await _catalog());
    final term = query?.trim().toLowerCase();
    return all.where((t) {
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (term != null && term.isNotEmpty) {
        return t.name.toLowerCase().contains(term) ||
            t.description.toLowerCase().contains(term);
      }
      return true;
    }).toList();
  }

  @override
  Future<Treatment> getTreatmentDetail(String id) async {
    final all = _parseTreatments(await _catalog());
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => throw const ApiException('Treatment not found', 404),
    );
  }

  @override
  Future<List<Addon>> getAddons() async {
    final json = await _catalog();
    return (json['addons'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          (a) => Addon(
            id: a['id'] as String,
            name: a['name'] as String,
            description: (a['note'] as String?) ?? '',
            price: (a['priceIdr'] as num).toDouble(),
            kind: (a['kind'] as String?) ?? 'immediate',
            durationMinutes: (a['durationMin'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }
}
