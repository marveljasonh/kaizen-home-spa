import 'package:dartz/dartz.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/addon.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/entities/treatment_category.dart';
import '../../domain/repositories/treatments_repository.dart';
import '../datasources/treatments_remote_datasource.dart';

class TreatmentsRepositoryImpl implements TreatmentsRepository {
  final TreatmentsRemoteDataSource _dataSource;
  const TreatmentsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<TreatmentCategory>>> getCategories() async {
    try {
      return Right(await _dataSource.getCategories());
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Treatment>>> getTreatments({
    String? categoryId,
    String? query,
  }) async {
    try {
      return Right(
        await _dataSource.getTreatments(categoryId: categoryId, query: query),
      );
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Treatment>> getTreatmentDetail(String id) async {
    try {
      return Right(await _dataSource.getTreatmentDetail(id));
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Addon>>> getAddons() async {
    try {
      return Right(await _dataSource.getAddons());
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
