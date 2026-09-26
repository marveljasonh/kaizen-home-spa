import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/notification_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import 'auth_state.dart';

final _authDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(Supabase.instance.client),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(_authDataSourceProvider)),
);

final _signInUseCaseProvider = Provider<SignInUseCase>(
  (ref) => SignInUseCase(ref.watch(authRepositoryProvider)),
);

final _signUpUseCaseProvider = Provider<SignUpUseCase>(
  (ref) => SignUpUseCase(ref.watch(authRepositoryProvider)),
);

final _signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);

final authNotifierProvider = NotifierProvider<AuthNotifier, AppAuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AppAuthState> {
  @override
  AppAuthState build() {
    final sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      // Suppress while explicit methods manage state transitions
      if (state is AuthLoading) return;
      final session = data.session;
      state = session != null
          ? AuthAuthenticated(_mapUser(session.user))
          : const AuthUnauthenticated();
    });
    ref.onDispose(sub.cancel);

    final session = Supabase.instance.client.auth.currentSession;
    return session != null
        ? AuthAuthenticated(_mapUser(session.user))
        : const AuthUnauthenticated();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    final result = await ref
        .read(_signInUseCaseProvider)
        .call(email: email, password: password);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) {
        state = AuthAuthenticated(user);
        NotificationService.init();
      },
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AuthLoading();
    final result = await ref
        .read(_signUpUseCaseProvider)
        .call(email: email, password: password, name: name);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) {
        state = AuthAuthenticated(user);
        NotificationService.init();
      },
    );
  }

  /// Creates the account then immediately saves phone + gender to profiles.
  Future<void> signUpAndSaveProfile({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String gender,
  }) async {
    state = const AuthLoading();
    try {
      final client = Supabase.instance.client;
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      final user = response.user;
      if (user == null) {
        state = const AuthError('Sign up failed. Please try again.');
        return;
      }
      // Save phone + gender to profiles before surfacing authenticated state
      await client.from('profiles').upsert(
        {
          'id': user.id,
          'full_name': name,
          'phone': phone,
          'gender': gender,
          'role': 'client',
        },
        onConflict: 'id',
      );
      state = AuthAuthenticated(_mapUser(user));
      NotificationService.init();
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> refreshUser() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      state = AuthAuthenticated(AppUser(
        id: user.id,
        email: user.email ?? '',
        name: profile['full_name'] as String?,
        avatarUrl: profile['avatar_url'] as String?,
        phone: profile['phone'] as String?,
      ));
    } catch (_) {
      // Non-fatal — keep existing state
    }
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    final result = await ref.read(_signOutUseCaseProvider).call();
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const AuthUnauthenticated(),
    );
  }

  AppUser _mapUser(User user) => AppUser(
        id: user.id,
        email: user.email ?? '',
        name: user.userMetadata?['name'] as String?,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        phone: user.phone,
      );
}
