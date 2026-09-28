import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/addon.dart';
import '../entities/treatment.dart';
import '../entities/treatment_category.dart';

abstract interface class TreatmentsRepository {
  Future<Either<Failure, List<TreatmentCategory>>> getCategories();
  Future<Either<Failure, List<Treatment>>> getTreatments({
    String? categoryId,
    String? query,
  });
  Future<Either<Failure, Treatment>> getTreatmentDetail(String id);
  Future<Either<Failure, List<Addon>>> getAddons();
}
