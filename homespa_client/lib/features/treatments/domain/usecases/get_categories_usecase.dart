import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/treatment_category.dart';
import '../repositories/treatments_repository.dart';

class GetCategoriesUseCase {
  final TreatmentsRepository _repository;
  const GetCategoriesUseCase(this._repository);

  Future<Either<Failure, List<TreatmentCategory>>> call() =>
      _repository.getCategories();
}
