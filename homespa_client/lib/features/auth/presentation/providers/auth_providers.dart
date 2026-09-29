import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/auth_session.dart';
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
  (ref) => AuthRemoteDataSourceImpl(apiClient),
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

/// True from a successful sign-up until the welcome screen's Get Started, so
/// the router shows /welcome to new accounts only (not on a normal login).
final justSignedUpProvider = StateProvider<bool>((ref) => false);

final authNotifierProvider = NotifierProvider<AuthNotifier, AppAuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AppAuthState> {
  @override
  AppAuthState build() {
    // AuthSession.load() ran in main() before runApp, so this is in sync with
    // secure storage. Show the cached identity immediately and refresh the
    // full profile in the background.
    final session = AuthSession.current;
    if (session == null) return const AuthUnauthenticated();
    Future.microtask(refreshUser);
    return AuthAuthenticated(AppUser.fromSession(session));
  }

  Future<void> signIn({required String phone, required String password}) async {
    state = const AuthLoading();
    final result = await ref
        .read(_signInUseCaseProvider)
        .call(phone: phone, password: password);
    result.fold((failure) => state = AuthError(failure.message), (user) {
      state = AuthAuthenticated(user);
      NotificationService.init();
      refreshUser();
    });
  }

  /// Registers (or claims a legacy account), then saves email + gender to the
  /// profile before surfacing the authenticated state.
  Future<void> signUpAndSaveProfile({
    required String name,
    required String phone,
    required String password,
    String? email,
    String? gender,
    String? referralCode,
  }) async {
    state = const AuthLoading();
    final result = await ref
        .read(_signUpUseCaseProvider)
        .call(
          name: name,
          phone: phone,
          password: password,
          referralCode: referralCode,
        );
    if (result.isLeft()) {
      result.fold((failure) => state = AuthError(failure.message), (_) {});
      return;
    }
    final user = result.getOrElse(() => throw StateError('unreachable'));
    // Best-effort: profile extras must not block a successful registration.
    if ((email != null && email.isNotEmpty) || gender != null) {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(email: email, gender: gender);
    }
    // Set before the state change the router reacts to.
    ref.read(justSignedUpProvider.notifier).state = true;
    state = AuthAuthenticated(user);
    NotificationService.init();
    refreshUser();
  }

  /// Re-fetches the profile (points, avatar, email, gender) from the server.
  Future<void> refreshUser() async {
    if (AuthSession.current == null) return;
    final result = await ref.read(authRepositoryProvider).fetchProfile();
    result.fold(
      (_) {
        // Non-fatal — keep existing state
      },
      (user) => state = AuthAuthenticated(user),
    );
  }

  Future<void> signOut() async {
    ref.read(justSignedUpProvider.notifier).state = false;
    state = const AuthLoading();
    final result = await ref.read(_signOutUseCaseProvider).call();
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const AuthUnauthenticated(),
    );
  }
}
