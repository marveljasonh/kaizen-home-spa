import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';

abstract interface class AuthRemoteDataSource {
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;
  const AuthRemoteDataSourceImpl(this._client);

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) throw const AuthException('Sign in failed');
    return _mapUser(user);
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    final user = response.user;
    if (user == null) throw const AuthException('Sign up failed');
    return _mapUser(user);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  AppUser _mapUser(User user) => AppUser(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] as String?,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
      );
}
