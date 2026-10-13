import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';

import '../../data/datasources/treatments_remote_datasource.dart';
import '../../data/repositories/treatments_repository_impl.dart';
import '../../domain/entities/addon.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/treatment_category.dart';
import '../../domain/repositories/treatments_repository.dart';
import '../../domain/usecases/get_addons_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_treatment_detail_usecase.dart';
import '../../domain/usecases/get_treatments_usecase.dart';

// ── DI chain ──────────────────────────────────────────────────────────────────

final _treatmentsDataSourceProvider = Provider<TreatmentsRemoteDataSource>(
  (ref) => TreatmentsRemoteDataSourceImpl(apiClient),
);

final treatmentsRepositoryProvider = Provider<TreatmentsRepository>(
  (ref) => TreatmentsRepositoryImpl(ref.watch(_treatmentsDataSourceProvider)),
);

final _getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>(
  (ref) => GetCategoriesUseCase(ref.watch(treatmentsRepositoryProvider)),
);

final _getTreatmentsUseCaseProvider = Provider<GetTreatmentsUseCase>(
  (ref) => GetTreatmentsUseCase(ref.watch(treatmentsRepositoryProvider)),
);

final _getTreatmentDetailUseCaseProvider = Provider<GetTreatmentDetailUseCase>(
  (ref) => GetTreatmentDetailUseCase(ref.watch(treatmentsRepositoryProvider)),
);

final _getAddonsUseCaseProvider = Provider<GetAddonsUseCase>(
  (ref) => GetAddonsUseCase(ref.watch(treatmentsRepositoryProvider)),
);

// ── Simple selection state ────────────────────────────────────────────────────

class _SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedCategoryIdProvider =
    NotifierProvider<_SelectedCategoryNotifier, String?>(
      _SelectedCategoryNotifier.new,
    );

final selectedDurationIdProvider = StateProvider.family<String?, String>(
  (ref, treatmentId) => null,
);

// Pending category name set from outside (e.g. Home page category chips)
// The TreatmentsPage resolves this to an ID once categories are loaded.
final pendingCategoryNameProvider = StateProvider<String?>((ref) => null);

// Search query for client-side filtering on treatments list
final treatmentsSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Data providers ────────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<TreatmentCategory>>((ref) async {
  final result = await ref.read(_getCategoriesUseCaseProvider).call();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (categories) => categories,
  );
});

final treatmentsProvider = FutureProvider.family<List<Treatment>, String?>((
  ref,
  categoryId,
) async {
  final result = await ref
      .read(_getTreatmentsUseCaseProvider)
      .call(categoryId: categoryId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (treatments) => treatments,
  );
});

final treatmentDetailProvider = FutureProvider.family<Treatment, String>((
  ref,
  id,
) async {
  final result = await ref.read(_getTreatmentDetailUseCaseProvider).call(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (treatment) => treatment,
  );
});

final addonsProvider = FutureProvider<List<Addon>>((ref) async {
  final result = await ref.read(_getAddonsUseCaseProvider).call();
  return result.fold((failure) => <Addon>[], (addons) => addons);
});
