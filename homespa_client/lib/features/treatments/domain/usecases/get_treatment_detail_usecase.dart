import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/treatment.dart';
import '../repositories/treatments_repository.dart';

class GetTreatmentDetailUseCase {
  final TreatmentsRepository _repository;
  const GetTreatmentDetailUseCase(this._repository);

  Future<Either<Failure, Treatment>> call(String id) =>
      _repository.getTreatmentDetail(id);
}
