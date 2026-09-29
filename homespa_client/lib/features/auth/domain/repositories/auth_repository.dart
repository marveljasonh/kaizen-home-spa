import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// Logs in with phone + password; persists the session on success.
  Future<Either<Failure, AppUser>> signIn({
    required String phone,
    required String password,
  });

  /// Registers (or claims a legacy account by phone); persists the session.
  Future<Either<Failure, AppUser>> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? referralCode,
  });

  /// Fresh profile from the server for the signed-in customer.
  Future<Either<Failure, AppUser>> fetchProfile();

  /// Updates name/email/gender on the signed-in customer's profile.
  Future<Either<Failure, void>> updateProfile({
    String? name,
    String? email,
    String? gender,
  });

  Future<Either<Failure, void>> signOut();

  /// Cached identity from the persisted session (no network).
  AppUser? get currentUser;
}
