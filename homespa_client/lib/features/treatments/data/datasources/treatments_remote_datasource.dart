import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/addon.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/treatment_category.dart';
import '../models/addon_model.dart';
import '../models/category_model.dart';
import '../models/treatment_model.dart';
import '../models/treatment_duration_model.dart';

abstract interface class TreatmentsRemoteDataSource {
  Future<List<TreatmentCategory>> getCategories();

  /// [query] matches name or description (case-insensitive substring).
  Future<List<Treatment>> getTreatments({String? categoryId, String? query});
  Future<Treatment> getTreatmentDetail(String id);
  Future<List<Addon>> getAddons();
}

class TreatmentsRemoteDataSourceImpl implements TreatmentsRemoteDataSource {
  final SupabaseClient _client;
  const TreatmentsRemoteDataSourceImpl(this._client);

  @override
  Future<List<TreatmentCategory>> getCategories() async {
    final data = await _client.from('categories').select().order('name');
    return data.map((e) => CategoryModel.fromJson(e)).toList();
  }

  @override
  Future<List<Treatment>> getTreatments({
    String? categoryId,
    String? query,
  }) async {
    final user = _client.auth.currentUser;
    print('[TreatmentsDS] auth user: ${user?.id ?? 'NOT LOGGED IN'}');

    try {
      // Step 1: flat treatments query — no embedded joins
      var request = _client.from('treatments').select().eq('is_active', true);

      if (categoryId != null) {
        request = request.eq('category_id', categoryId);
      }

      // Characters that would break PostgREST's or=(…) syntax or act as
      // wildcards are dropped from the user's text.
      final term = query?.replaceAll(RegExp(r'[,()%*_\\.]'), ' ').trim();
      if (term != null && term.isNotEmpty) {
        request = request.or('name.ilike.%$term%,description.ilike.%$term%');
      }

      final treatmentsData = await request.order('name');
      print('[TreatmentsDS] treatments rows: ${treatmentsData.length}');
      if (treatmentsData.isNotEmpty)
        print('[TreatmentsDS] first row: ${treatmentsData.first}');
      if (treatmentsData.isEmpty) return [];

      final treatmentIds = treatmentsData
          .map((t) => t['id'] as String)
          .toList();

      // Step 2: fetch categories for name resolution
      final categoryIds = treatmentsData
          .map((t) => t['category_id'] as String)
          .toSet()
          .toList();
      final categoriesData = await _client
          .from('categories')
          .select('id, name')
          .inFilter('id', categoryIds);
      print('[TreatmentsDS] categories rows: ${categoriesData.length}');
      final categoryNameById = {
        for (final c in categoriesData) c['id'] as String: c['name'] as String,
      };

      // Step 3: batch-fetch durations
      final durationsData = await _client
          .from('treatment_durations')
          .select()
          .inFilter('treatment_id', treatmentIds);
      print('[TreatmentsDS] durations rows: ${durationsData.length}');
      final durationsByTreatmentId = <String, List<Map<String, dynamic>>>{};
      for (final d in durationsData) {
        final tid = d['treatment_id'] as String;
        durationsByTreatmentId.putIfAbsent(tid, () => []).add(d);
      }

      // Step 4: assemble and parse
      return treatmentsData.map((t) {
        final tid = t['id'] as String;
        return TreatmentModel.fromFlat(
          row: t,
          categoryName: categoryNameById[t['category_id']] ?? '',
          durationsData: durationsByTreatmentId[tid] ?? [],
        );
      }).toList();
    } on PostgrestException catch (e) {
      print(
        '[TreatmentsDS] PostgrestException: code=${e.code} message=${e.message} details=${e.details} hint=${e.hint}',
      );
      rethrow;
    } catch (e, st) {
      print('[TreatmentsDS] unexpected error: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<Treatment> getTreatmentDetail(String id) async {
    // Step 1: fetch the treatment row
    final row = await _client.from('treatments').select().eq('id', id).single();

    // Step 2: fetch category name
    final categoryData = await _client
        .from('categories')
        .select('id, name')
        .eq('id', row['category_id'] as String)
        .single();

    // Step 3: fetch durations
    final durationsData = await _client
        .from('treatment_durations')
        .select()
        .eq('treatment_id', id)
        .order('duration_minutes');

    return TreatmentModel.fromFlat(
      row: row,
      categoryName: categoryData['name'] as String? ?? '',
      durationsData: List<Map<String, dynamic>>.from(durationsData),
    );
  }

  @override
  Future<List<Addon>> getAddons() async {
    try {
      final data = await _client
          .from('addons')
          .select()
          .eq('is_active', true)
          .order('name');
      print('[AddonsDS] rows: ${data.length}');
      return data.map((e) => AddonModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      print(
        '[AddonsDS] PostgrestException: code=${e.code} message=${e.message} details=${e.details} hint=${e.hint}',
      );
      rethrow;
    } catch (e, st) {
      print('[AddonsDS] unexpected error: $e\n$st');
      rethrow;
    }
  }
}
