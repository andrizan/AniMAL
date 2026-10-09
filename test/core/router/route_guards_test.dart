import 'package:animal/core/providers.dart';
import 'package:animal/core/router/app_router.dart';
import 'package:animal/core/router/route_guards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeState extends Fake implements GoRouterState {
  _FakeState(this.matchedLocation);

  @override
  final String matchedLocation;
}

void main() {
  String? guard(String location, AuthStatus status) =>
      authGuard(_FakeState(location), status);

  group('signed out', () {
    for (final status in [AuthStatus.unauthenticated, AuthStatus.unknown]) {
      test('is sent to login from any private page ($status)', () {
        expect(guard('/home', status), AppRoutes.login);
        expect(guard('/anime/42', status), AppRoutes.login);
        expect(guard('/search', status), AppRoutes.login);
      });

      test('may stay on login and the oauth callback ($status)', () {
        expect(guard(AppRoutes.login, status), isNull);
        expect(guard(AppRoutes.oauthCallback, status), isNull);
      });
    }
  });

  group('signed in', () {
    test('is sent home when opening login', () {
      expect(guard(AppRoutes.login, AuthStatus.authenticated), '/home');
    });

    test('is left alone elsewhere, including the oauth callback', () {
      expect(guard('/home', AuthStatus.authenticated), isNull);
      expect(guard('/anime/42', AuthStatus.authenticated), isNull);
      expect(guard(AppRoutes.oauthCallback, AuthStatus.authenticated), isNull);
    });
  });
}
