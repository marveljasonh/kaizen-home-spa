import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/therapist.dart';
import '../repositories/booking_repository.dart';

class GetTherapistsUseCase {
  final BookingRepository _repository;
  const GetTherapistsUseCase(this._repository);

  Future<Either<Failure, List<Therapist>>> call() =>
      _repository.getTherapists();
}
