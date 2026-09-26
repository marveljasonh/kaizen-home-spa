import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/booking_record.dart';
import '../repositories/booking_repository.dart';

class GetBookingHistoryUseCase {
  final BookingRepository _repository;
  const GetBookingHistoryUseCase(this._repository);

  Future<Either<Failure, List<BookingRecord>>> call() =>
      _repository.getBookingHistory();
}
