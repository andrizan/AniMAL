import 'package:animal/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Loads every Figtree weight the themes use from the bundled assets.
///
/// Flutter 3.50 schedules a frame callback whenever the engine reports a font
/// change, so a font that finishes loading after a test's last pump leaves a
/// transient callback behind and fails the test.
Future<void> loadThemeFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  buildLightTheme();
  buildDarkTheme();
  await GoogleFonts.pendingFonts();
}

void restoreFontFetching() => GoogleFonts.config.allowRuntimeFetching = true;
