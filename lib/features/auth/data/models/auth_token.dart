import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_token.freezed.dart';
part 'auth_token.g.dart';

/// Represents an OAuth2 token pair from MyAnimeList.
@freezed
sealed class AuthToken with _$AuthToken {
  const factory AuthToken({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'expires_in') required int expiresIn,
    @JsonKey(name: 'token_type') @Default('Bearer') String tokenType,
  }) = _AuthToken;

  factory AuthToken.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenFromJson(json);
}
