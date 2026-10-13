import 'package:dartz/dartz.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/booking_record.dart';
import '../../domain/entities/booking_request.dart';
import '../../domain/entities/therapist.dart';
import '../../domain/entities/voucher.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _dataSource;
  const BookingRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<Therapist>>> getTherapists() async {
    try {
      return Right(await _dataSource.getTherapists());
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Voucher>> validateVoucher(String code) async {
    try {
      return Right(await _dataSource.validateVoucher(code));
    } on ApiException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createBooking(BookingRequest request) async {
    try {
      return Right(await _dataSource.createBooking(request));
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BookingRecord>>> getBookingHistory() async {
    try {
      return Right(await _dataSource.getBookingHistory());
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
