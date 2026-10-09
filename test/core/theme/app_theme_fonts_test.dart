import 'package:animal/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => GoogleFonts.config.allowRuntimeFetching = true);

  test('themes load every Inter weight from the bundled assets', () async {
    buildLightTheme();
    buildDarkTheme();

    await expectLater(GoogleFonts.pendingFonts(), completes);
  });
}
