import 'package:animal/core/theme/app_theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => GoogleFonts.config.allowRuntimeFetching = true);

  for (final (name, build) in [
    ('light', buildLightTheme),
    ('dark', buildDarkTheme),
  ]) {
    test('$name cards share one rounded, bordered, filled style', () {
      final theme = build();
      final card = theme.cardTheme;
      final shape = card.shape! as RoundedRectangleBorder;

      expect(card.elevation, 0);
      expect(card.color, theme.colorScheme.surfaceContainer);
      expect(shape.borderRadius, BorderRadius.circular(appCardRadius));
      expect(shape.side.color, theme.colorScheme.outlineVariant);
    });
  }

  test('both themes use the same card radius and border width', () {
    final light = buildLightTheme().cardTheme.shape! as RoundedRectangleBorder;
    final dark = buildDarkTheme().cardTheme.shape! as RoundedRectangleBorder;

    expect(light.borderRadius, dark.borderRadius);
    expect(light.side.width, dark.side.width);
  });
}
