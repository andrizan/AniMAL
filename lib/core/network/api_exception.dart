import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_exception.freezed.dart';

/// Represents API errors in a type-safe manner.
@freezed
sealed class ApiException with _$ApiException implements Exception {
  /// Network-level error (no internet, DNS, timeout, etc.).
  const factory ApiException.network({required String message}) =
      NetworkException;

  /// Server returned a non-2xx status code.
  const factory ApiException.server({
    required int statusCode,
    required String message,
  }) = ServerException;

  /// Failed to parse the response body.
  const factory ApiException.parsing({required String message}) =
      ParsingException;

  /// Authentication error (401 / token expired).
  const factory ApiException.unauthorized({String? message}) =
      UnauthorizedException;

  /// Unknown / unexpected error.
  const factory ApiException.unknown({String? message}) = UnknownApiException;
}
