import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;
  const SignInUseCase(this._repository);

  Future<Either<Failure, AppUser>> call({
    required String phone,
    required String password,
  }) => _repository.signIn(phone: phone, password: password);
}
