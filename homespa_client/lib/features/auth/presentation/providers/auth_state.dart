import '../../domain/entities/app_user.dart';

sealed class AppAuthState {
  const AppAuthState();
}

final class AuthUnauthenticated extends AppAuthState {
  const AuthUnauthenticated();
}

final class AuthLoading extends AppAuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AppAuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);
}

final class AuthError extends AppAuthState {
  final String message;
  const AuthError(this.message);
}
