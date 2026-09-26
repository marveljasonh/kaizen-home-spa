import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/addon.dart';
import '../repositories/treatments_repository.dart';

class GetAddonsUseCase {
  final TreatmentsRepository _repository;
  const GetAddonsUseCase(this._repository);

  Future<Either<Failure, List<Addon>>> call() => _repository.getAddons();
}
