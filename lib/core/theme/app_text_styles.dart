import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Figtree type scale. Line heights stay at 1.4 or more for body copy and
/// nothing is smaller than 12px (`labelSmall`).
abstract final class AppTextStyles {
  static TextTheme build(ColorScheme colorScheme) {
    final color = colorScheme.onSurface;

    TextStyle style(double size, double lineHeight, FontWeight weight) =>
        GoogleFonts.figtree(
          fontSize: size,
          height: lineHeight / size,
          fontWeight: weight,
          color: color,
        );

    return TextTheme(
      displayLarge: style(57, 64, FontWeight.w700),
      displayMedium: style(45, 52, FontWeight.w700),
      displaySmall: style(36, 44, FontWeight.w700),
      headlineLarge: style(32, 40, FontWeight.w700),
      headlineMedium: style(28, 36, FontWeight.w700),
      headlineSmall: style(24, 32, FontWeight.w700),
      titleLarge: style(22, 28, FontWeight.w600),
      titleMedium: style(16, 22, FontWeight.w600),
      titleSmall: style(14, 20, FontWeight.w600),
      bodyLarge: style(16, 24, FontWeight.w400),
      bodyMedium: style(14, 20, FontWeight.w400),
      bodySmall: style(13, 19, FontWeight.w400),
      labelLarge: style(14, 20, FontWeight.w600),
      labelMedium: style(13, 18, FontWeight.w600),
      labelSmall: style(12, 16, FontWeight.w600),
    );
  }
}
