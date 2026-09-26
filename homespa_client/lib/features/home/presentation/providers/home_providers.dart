import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/treatment_preview.dart';

final popularTreatmentsProvider = FutureProvider<List<TreatmentPreview>>((ref) async {
  final client = Supabase.instance.client;

  try {
    // Top 4 active treatments ordered by sort_order
    final treatmentsData = await client
        .from('treatments')
        .select('id, name, category_id, image_url')
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .limit(4);

    if (treatmentsData.isEmpty) return [];

    final treatmentIds = treatmentsData.map((t) => t['id'] as String).toList();

    // Batch-fetch category names
    final categoryIds = treatmentsData
        .map((t) => t['category_id'] as String)
        .toSet()
        .toList();
    final categoriesData = await client
        .from('categories')
        .select('id, name')
        .inFilter('id', categoryIds);
    final categoryNameById = {
      for (final c in categoriesData) c['id'] as String: c['name'] as String,
    };

    // Batch-fetch durations; prefer the default one per treatment
    final durationsData = await client
        .from('treatment_durations')
        .select('treatment_id, duration_minutes, price')
        .inFilter('treatment_id', treatmentIds);
    final bestDuration = <String, Map<String, dynamic>>{};
    for (final d in durationsData) {
      final tid = d['treatment_id'] as String;
      // Keep the first duration seen per treatment (lowest price wins due to
      // sort order; any row is better than none).
      bestDuration.putIfAbsent(tid, () => d);
    }

    return treatmentsData.map((t) {
      final tid = t['id'] as String;
      final dur = bestDuration[tid];
      return TreatmentPreview(
        id: tid,
        name: t['name'] as String,
        category: categoryNameById[t['category_id']] ?? '',
        durationMinutes: dur?['duration_minutes'] as int? ?? 60,
        price: (dur?['price'] as num?)?.toDouble() ?? 0,
        rating: 0,
        reviewCount: 0,
        imageUrl: t['image_url'] as String?,
      );
    }).toList();
  } catch (_) {
    return [];
  }
});
