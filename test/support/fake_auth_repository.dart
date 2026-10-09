import 'package:animal/data/models/auth_token.dart';
import 'package:animal/features/auth/data/repositories/mal_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const fakeToken = AuthToken(
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresIn: 3600,
);

class FakeAuthRepository extends Fake implements MalAuthRepository {
  bool authenticated = false;
  Object? exchangeError;
  AuthToken? refreshResult;
  final exchanged = <String>[];
  int logouts = 0;

  @override
  Future<bool> get isAuthenticated async => authenticated;

  @override
  Future<Uri> buildAuthorizationUrl() async =>
      Uri.parse('https://auth.test/authorize');

  @override
  Future<AuthToken> exchangeCode(String authorizationCode) async {
    exchanged.add(authorizationCode);
    final error = exchangeError;
    if (error != null) throw error;
    authenticated = true;
    return fakeToken;
  }

  @override
  Future<AuthToken?> refreshToken() async => refreshResult;

  @override
  Future<void> logout() async {
    logouts++;
    authenticated = false;
  }
}
