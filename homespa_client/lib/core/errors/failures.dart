sealed class Failure {
  final String message;
  const Failure(this.message);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
