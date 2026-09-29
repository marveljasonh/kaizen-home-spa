import 'package:dartz/dartz.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/auth_session.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  const AuthRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String phone,
    required String password,
  }) async {
    try {
      final session = await _dataSource.signIn(
        phone: phone,
        password: password,
      );
      await session.save();
      return Right(AppUser.fromSession(session));
    } on ApiException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signUp({
    required String name,
    required String phone,
    required String password,
    String? referralCode,
  }) async {
    try {
      final session = await _dataSource.register(
        name: name,
        phone: phone,
        password: password,
        referralCode: referralCode,
      );
      await session.save();
      return Right(AppUser.fromSession(session));
    } on ApiException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> fetchProfile() async {
    final session = AuthSession.current;
    if (session == null) return const Left(AuthFailure('Not signed in'));
    try {
      final user = await _dataSource.fetchProfile(session.customerId);
      return Right(user);
    } on ApiException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? name,
    String? email,
    String? gender,
  }) async {
    final session = AuthSession.current;
    if (session == null) return const Left(AuthFailure('Not signed in'));
    try {
      await _dataSource.updateProfile(
        session.customerId,
        name: name,
        email: email,
        gender: gender,
      );
      return const Right(null);
    } on ApiException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    await AuthSession.clear();
    return const Right(null);
  }

  @override
  AppUser? get currentUser {
    final session = AuthSession.current;
    if (session == null) return null;
    return AppUser.fromSession(session);
  }
}
