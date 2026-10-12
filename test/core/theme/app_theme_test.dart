import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => GoogleFonts.config.allowRuntimeFetching = true);

  for (final (name, build) in [
    ('light', buildLightTheme),
    ('dark', buildDarkTheme),
  ]) {
    test('$name cards share one rounded, borderless, filled style', () {
      final theme = build();
      final card = theme.cardTheme;
      final shape = card.shape! as RoundedRectangleBorder;

      expect(card.color, theme.colorScheme.surfaceContainerLow);
      expect(card.surfaceTintColor, AppColors.transparent);
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.card));
      expect(shape.side, BorderSide.none);
    });

    test('$name tab labels are theme driven, bold only when selected', () {
      final tabs = build().tabBarTheme;

      expect(tabs.labelStyle!.fontSize, 14);
      expect(tabs.labelStyle!.fontWeight, FontWeight.w600);
      expect(tabs.unselectedLabelStyle!.fontSize, 14);
      expect(tabs.unselectedLabelStyle!.fontWeight, FontWeight.w500);
      expect(tabs.indicatorSize, TabBarIndicatorSize.tab);
    });

    test('$name compact labels use the 12px micro style', () {
      final micro = build().textTheme.labelSmall!;

      expect(micro.fontSize, 12);
      expect(micro.fontWeight, FontWeight.w600);
    });

    test('$name body copy keeps a line height of at least 1.4', () {
      final text = build().textTheme;

      expect(text.bodyLarge!.fontSize, 15);
      for (final style in [text.bodyLarge, text.bodyMedium]) {
        expect(style!.height, greaterThanOrEqualTo(1.4));
      }
    });

    test('$name installs the status colours of its brightness', () {
      final theme = build();

      expect(
        theme.extension<StatusColors>(),
        name == 'dark' ? AppColors.darkStatus : AppColors.lightStatus,
      );
    });
  }

  test('light cards carry a soft shadow, dark cards rely on tone', () {
    expect(buildLightTheme().cardTheme.elevation, greaterThan(0));
    expect(buildDarkTheme().cardTheme.elevation, 0);
  });

  test('both themes use the same card radius', () {
    final light = buildLightTheme().cardTheme.shape! as RoundedRectangleBorder;
    final dark = buildDarkTheme().cardTheme.shape! as RoundedRectangleBorder;

    expect(light.borderRadius, dark.borderRadius);
  });
}
