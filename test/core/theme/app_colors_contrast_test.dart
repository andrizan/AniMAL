import 'package:animal/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// WCAG 2.2 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

typedef _Pair = (String name, Color foreground, Color background, double min);

const _text = 4.5;
const _enhancedText = 7.0;
const _nonText = 3.0;

void main() {
  test('the contrast helper matches the WCAG reference values', () {
    expect(_contrast(Colors.black, Colors.white), closeTo(21, 0.001));
    expect(_contrast(Colors.white, Colors.white), closeTo(1, 0.001));
    // #767676 on white is the classic 4.54:1 AA threshold example.
    expect(
      _contrast(const Color(0xFF767676), Colors.white),
      closeTo(4.54, 0.01),
    );
  });

  for (final (name, scheme) in [
    ('light', AppColors.light),
    ('dark', AppColors.dark),
  ]) {
    group('$name scheme', () {
      final surfaces = <(String, Color)>[
        ('surface', scheme.surface),
        ('surfaceContainerLow', scheme.surfaceContainerLow),
        ('surfaceContainer', scheme.surfaceContainer),
        ('surfaceContainerHigh', scheme.surfaceContainerHigh),
      ];

      test('body text reads at AAA on every surface', () {
        for (final (surfaceName, surface) in surfaces) {
          expect(
            _contrast(scheme.onSurface, surface),
            greaterThanOrEqualTo(_enhancedText),
            reason: 'onSurface on $surfaceName',
          );
        }
      });

      test('secondary text reads at AA on every surface', () {
        for (final (surfaceName, surface) in surfaces) {
          expect(
            _contrast(scheme.onSurfaceVariant, surface),
            greaterThanOrEqualTo(_text),
            reason: 'onSurfaceVariant on $surfaceName',
          );
        }
      });

      test('accent text and filled controls read at AA', () {
        final pairs = <_Pair>[
          ('primary on surface', scheme.primary, scheme.surface, _text),
          (
            'primary on card',
            scheme.primary,
            scheme.surfaceContainerLow,
            _text,
          ),
          ('primary on tonal', scheme.primary, scheme.surfaceContainer, _text),
          ('onPrimary on primary', scheme.onPrimary, scheme.primary, _text),
          (
            'onPrimaryContainer on primaryContainer',
            scheme.onPrimaryContainer,
            scheme.primaryContainer,
            _enhancedText,
          ),
          (
            'onSecondary on secondary',
            scheme.onSecondary,
            scheme.secondary,
            _text,
          ),
          (
            'onSecondaryContainer on secondaryContainer',
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
            _enhancedText,
          ),
          ('onTertiary on tertiary', scheme.onTertiary, scheme.tertiary, _text),
          (
            'onTertiaryContainer on tertiaryContainer',
            scheme.onTertiaryContainer,
            scheme.tertiaryContainer,
            _enhancedText,
          ),
          ('onError on error', scheme.onError, scheme.error, _text),
          (
            'onErrorContainer on errorContainer',
            scheme.onErrorContainer,
            scheme.errorContainer,
            _enhancedText,
          ),
          ('error text on surface', scheme.error, scheme.surface, _text),
          (
            'onInverseSurface on inverseSurface',
            scheme.onInverseSurface,
            scheme.inverseSurface,
            _text,
          ),
          (
            'inversePrimary on inverseSurface',
            scheme.inversePrimary,
            scheme.inverseSurface,
            _nonText,
          ),
        ];

        for (final (label, foreground, background, min) in pairs) {
          expect(
            _contrast(foreground, background),
            greaterThanOrEqualTo(min),
            reason: label,
          );
        }
      });

      test('control edges and focus colours clear 3:1 on the card', () {
        for (final (label, color) in [
          ('outline', scheme.outline),
          ('primary', scheme.primary),
          ('error', scheme.error),
          ('secondary (chart bars)', scheme.secondary),
        ]) {
          expect(
            _contrast(color, scheme.surfaceContainerLow),
            greaterThanOrEqualTo(_nonText),
            reason: label,
          );
        }
        expect(
          _contrast(scheme.outline, scheme.surface),
          greaterThanOrEqualTo(_nonText),
          reason: 'outline on the page background',
        );
      });
    });
  }

  for (final (name, status, scheme) in [
    ('light', AppColors.lightStatus, AppColors.light),
    ('dark', AppColors.darkStatus, AppColors.dark),
  ]) {
    group('$name status colours', () {
      test('every tonal chip pair reads at AAA', () {
        final pairs = <(String, Color, Color)>[
          ('airing', status.onAiringContainer, status.airingContainer),
          ('finished', status.onFinishedContainer, status.finishedContainer),
          ('upcoming', status.onUpcomingContainer, status.upcomingContainer),
          ('dropped', status.onDroppedContainer, status.droppedContainer),
          ('plan', status.onPlanContainer, status.planContainer),
        ];

        for (final (label, foreground, background) in pairs) {
          expect(
            _contrast(foreground, background),
            greaterThanOrEqualTo(_enhancedText),
            reason: label,
          );
        }
      });

      test('solid marks and the star clear 3:1 on the card', () {
        for (final (label, color) in [
          ('watching', status.listWatching),
          ('completed', status.listCompleted),
          ('on hold', status.listOnHold),
          ('dropped', status.listDropped),
          ('plan to watch', status.listPlanToWatch),
          ('star', status.star),
        ]) {
          expect(
            _contrast(color, scheme.surfaceContainerLow),
            greaterThanOrEqualTo(_nonText),
            reason: label,
          );
        }
      });

      test('the five list marks are all different colours', () {
        final marks = {
          status.listWatching,
          status.listCompleted,
          status.listOnHold,
          status.listDropped,
          status.listPlanToWatch,
        };

        expect(marks, hasLength(5));
      });
    });
  }

  group('chart palettes', () {
    test('keep five distinct colours in a fixed order', () {
      for (final palette in [
        AppColors.chartPalette,
        AppColors.chartPaletteDark,
      ]) {
        expect(palette, hasLength(5));
        expect(palette.toSet(), hasLength(5));
      }
    });

    test('each colour clears 3:1 on the card of its own theme', () {
      for (final color in AppColors.chartPalette) {
        expect(
          _contrast(color, AppColors.light.surfaceContainerLow),
          greaterThanOrEqualTo(_nonText),
          reason: '$color on the light card',
        );
      }
      for (final color in AppColors.chartPaletteDark) {
        expect(
          _contrast(color, AppColors.dark.surfaceContainerLow),
          greaterThanOrEqualTo(_nonText),
          reason: '$color on the dark card',
        );
      }
    });

    test('match the list status marks they stand for', () {
      expect(
        AppColors.chartPalette.toSet(),
        containsAll({
          AppColors.lightStatus.listWatching,
          AppColors.lightStatus.listCompleted,
          AppColors.lightStatus.listOnHold,
          AppColors.lightStatus.listDropped,
          AppColors.lightStatus.listPlanToWatch,
        }),
      );
      expect(
        AppColors.chartPaletteDark.toSet(),
        containsAll({
          AppColors.darkStatus.listWatching,
          AppColors.darkStatus.listCompleted,
          AppColors.darkStatus.listOnHold,
          AppColors.darkStatus.listDropped,
          AppColors.darkStatus.listPlanToWatch,
        }),
      );
    });
  });

  group('overlays on imagery', () {
    test('white controls read at AAA on the scrim over a white cover', () {
      final scrim = Color.alphaBlend(AppColors.overlayDarker, Colors.white);

      expect(
        _contrast(AppColors.iconLight, scrim),
        greaterThanOrEqualTo(_enhancedText),
      );
    });

    test('white controls read at AAA on the scrim over a black cover', () {
      final scrim = Color.alphaBlend(AppColors.overlayDarker, Colors.black);

      expect(
        _contrast(AppColors.iconLight, scrim),
        greaterThanOrEqualTo(_enhancedText),
      );
    });

    test(
      'the brand mark keeps its white glyph visible at both gradient ends',
      () {
        for (final end in AppColors.brandGradient) {
          expect(
            _contrast(AppColors.iconLight, end),
            greaterThanOrEqualTo(_nonText),
            reason: '$end',
          );
        }
      },
    );
  });
}
