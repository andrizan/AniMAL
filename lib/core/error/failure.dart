import 'package:animal/core/network/api_exception.dart';

sealed class Failure {
  const Failure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure(this.message);
  final String message;
}

final class ServerFailure extends Failure {
  const ServerFailure(this.statusCode, this.message);
  final int statusCode;
  final String message;
}

final class AuthFailure extends Failure {
  const AuthFailure([this.message]);
  final String? message;
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([this.message]);
  final String? message;
}

final class UnknownFailure extends Failure {
  const UnknownFailure([this.message]);
  final String? message;
}

Failure mapApiExceptionToFailure(ApiException e) {
  return e.map(
    network: (e) => NetworkFailure(e.message),
    server: (e) => ServerFailure(e.statusCode, e.message),
    parsing: (e) => UnknownFailure(e.message),
    unauthorized: (e) => AuthFailure(e.message),
    unknown: (e) => UnknownFailure(e.message),
  );
}
