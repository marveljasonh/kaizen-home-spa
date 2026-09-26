import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;
  const SignUpUseCase(this._repository);

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
    required String name,
  }) =>
      _repository.signUpWithEmail(email: email, password: password, name: name);
}
