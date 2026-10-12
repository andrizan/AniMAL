import 'dart:io';

import 'package:animal/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => GoogleFonts.config.allowRuntimeFetching = true);

  test('themes load every Figtree weight from the bundled assets', () async {
    buildLightTheme();
    buildDarkTheme();

    await expectLater(GoogleFonts.pendingFonts(), completes);
  });

  test('all four weights ship with the app', () {
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      expect(
        File('assets/google_fonts/Figtree-$weight.ttf').existsSync(),
        isTrue,
        reason: 'Figtree-$weight.ttf',
      );
    }
  });

  test('the font folder is declared as an asset', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/google_fonts/'),
    );
  });
}
