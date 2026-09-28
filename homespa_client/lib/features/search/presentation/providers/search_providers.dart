import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../treatments/domain/entities/treatment.dart';
import '../../../treatments/presentation/providers/treatments_providers.dart';

/// Active treatments whose name or description contains [query]
/// (Supabase `ilike`, flat queries — see TreatmentsRemoteDataSource).
final treatmentSearchProvider = FutureProvider.autoDispose
    .family<List<Treatment>, String>((ref, query) async {
      if (query.trim().isEmpty) return const [];
      final result = await ref
          .read(treatmentsRepositoryProvider)
          .getTreatments(query: query);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (treatments) => treatments,
      );
    });
