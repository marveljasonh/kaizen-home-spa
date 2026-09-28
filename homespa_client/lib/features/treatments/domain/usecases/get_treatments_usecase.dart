import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/treatment.dart';
import '../repositories/treatments_repository.dart';

class GetTreatmentsUseCase {
  final TreatmentsRepository _repository;
  const GetTreatmentsUseCase(this._repository);

  Future<Either<Failure, List<Treatment>>> call({
    String? categoryId,
    String? query,
  }) => _repository.getTreatments(categoryId: categoryId, query: query);
}
