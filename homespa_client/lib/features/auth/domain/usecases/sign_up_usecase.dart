import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;
  const SignUpUseCase(this._repository);

  Future<Either<Failure, AppUser>> call({
    required String name,
    required String phone,
    required String password,
    String? referralCode,
  }) => _repository.signUp(
    name: name,
    phone: phone,
    password: password,
    referralCode: referralCode,
  );
}
