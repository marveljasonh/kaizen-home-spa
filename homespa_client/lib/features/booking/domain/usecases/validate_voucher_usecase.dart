import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/voucher.dart';
import '../repositories/booking_repository.dart';

class ValidateVoucherUseCase {
  final BookingRepository _repository;
  const ValidateVoucherUseCase(this._repository);

  Future<Either<Failure, Voucher>> call(String code) =>
      _repository.validateVoucher(code);
}
