import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/booking_record.dart';
import '../entities/booking_request.dart';
import '../entities/therapist.dart';
import '../entities/voucher.dart';

abstract interface class BookingRepository {
  Future<Either<Failure, List<Therapist>>> getTherapists();
  Future<Either<Failure, Voucher>> validateVoucher(String code);
  Future<Either<Failure, String>> createBooking(BookingRequest request);
  Future<Either<Failure, List<BookingRecord>>> getBookingHistory();
}
