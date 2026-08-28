/// Represents API errors in a type-safe manner.
sealed class ApiException implements Exception {
  const ApiException();

  const factory ApiException.network({required String message}) =
      NetworkException;

  const factory ApiException.server({
    required int statusCode,
    required String message,
  }) = ServerException;

  const factory ApiException.parsing({required String message}) =
      ParsingException;

  const factory ApiException.unauthorized({String? message}) =
      UnauthorizedException;

  const factory ApiException.unknown({String? message}) = UnknownApiException;

  const factory ApiException.rateLimited({
    required Duration retryAfter,
    String? message,
  }) = RateLimitException;
}

class NetworkException extends ApiException {
  const NetworkException({required this.message});
  final String message;
}

class ServerException extends ApiException {
  const ServerException({required this.statusCode, required this.message});
  final int statusCode;
  final String message;
}

class ParsingException extends ApiException {
  const ParsingException({required this.message});
  final String message;
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({this.message});
  final String? message;
}

class UnknownApiException extends ApiException {
  const UnknownApiException({this.message});
  final String? message;
}

/// HTTP 429 — caller decides fallback.
class RateLimitException extends ApiException {
  const RateLimitException({required this.retryAfter, this.message});
  final Duration retryAfter;
  final String? message;
}
