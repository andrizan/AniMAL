import 'dart:math' as math;

import 'package:animal/core/theme/app_spacing.dart';
import 'package:animal/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

const _focused = {WidgetState.focused};
const _selected = {WidgetState.selected};
const _disabled = {WidgetState.disabled};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final themes = {'light': buildLightTheme(), 'dark': buildDarkTheme()};

  tearDownAll(() async {
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  for (final entry in themes.entries) {
    final name = entry.key;
    final theme = entry.value;
    final scheme = theme.colorScheme;

    group('$name theme', () {
      group('focus rings', () {
        BorderSide? ring(ButtonStyle? style, Set<WidgetState> states) =>
            style?.side?.resolve(states);

        test('every button kind draws a 3px ring on keyboard focus', () {
          final styles = {
            'filled': theme.filledButtonTheme.style,
            'outlined': theme.outlinedButtonTheme.style,
            'text': theme.textButtonTheme.style,
            'icon': theme.iconButtonTheme.style,
            'segmented': theme.segmentedButtonTheme.style,
          };

          for (final style in styles.entries) {
            expect(ring(style.value, _focused)?.width, 3, reason: style.key);
          }
        });

        test(
          'filled buttons ring in the container colour, the rest in primary',
          () {
            expect(
              ring(theme.filledButtonTheme.style, _focused)?.color,
              scheme.primaryContainer,
            );
            for (final style in [
              theme.outlinedButtonTheme.style,
              theme.textButtonTheme.style,
              theme.iconButtonTheme.style,
              theme.segmentedButtonTheme.style,
            ]) {
              expect(ring(style, _focused)?.color, scheme.primary);
            }
          },
        );

        test('the ring only shows while focused', () {
          expect(ring(theme.filledButtonTheme.style, const {}), isNull);
          expect(ring(theme.textButtonTheme.style, _selected), isNull);
          expect(ring(theme.iconButtonTheme.style, const {}), isNull);
          expect(ring(theme.segmentedButtonTheme.style, _selected), isNull);
        });

        test('outlined buttons keep a visible outline at rest', () {
          final rest = ring(theme.outlinedButtonTheme.style, const {})!;

          expect(rest.color, scheme.outline);
          expect(rest.width, 1.5);
          expect(
            _contrast(rest.color, scheme.surface),
            greaterThanOrEqualTo(3),
          );
        });

        test('chips ring in primary and are otherwise borderless', () {
          final side = theme.chipTheme.side! as WidgetStateBorderSide;

          expect(side.resolve(_focused)?.width, 3);
          expect(side.resolve(_focused)?.color, scheme.primary);
          expect(side.resolve(const {}), BorderSide.none);
        });

        test('inputs thicken and recolour their border on focus', () {
          final decoration = theme.inputDecorationTheme;

          expect(
            (decoration.focusedBorder! as OutlineInputBorder).borderSide.width,
            2,
          );
          expect(
            (decoration.focusedBorder! as OutlineInputBorder).borderSide.color,
            scheme.primary,
          );
          expect(
            (decoration.enabledBorder! as OutlineInputBorder).borderSide.color,
            scheme.outline,
          );
          expect(
            (decoration.errorBorder! as OutlineInputBorder).borderSide.color,
            scheme.error,
          );
          expect(
            (decoration.focusedErrorBorder! as OutlineInputBorder)
                .borderSide
                .color,
            scheme.error,
          );
        });

        test('focus tint is a translucent primary', () {
          expect(theme.focusColor.a, closeTo(0.16, 0.01));
          expect(
            theme.focusColor.toARGB32() & 0xFFFFFF,
            scheme.primary.toARGB32() & 0xFFFFFF,
          );
        });
      });

      group('hit areas', () {
        test('primary and outlined buttons are 52px tall', () {
          expect(
            theme.filledButtonTheme.style!.minimumSize!.resolve(const {}),
            const Size(64, 52),
          );
          expect(
            theme.outlinedButtonTheme.style!.minimumSize!.resolve(const {}),
            const Size(64, 52),
          );
        });

        test('text buttons keep a 48px target', () {
          expect(
            theme.textButtonTheme.style!.minimumSize!.resolve(const {}),
            const Size(48, 48),
          );
        });

        test('buttons are pills', () {
          for (final style in [
            theme.filledButtonTheme.style,
            theme.outlinedButtonTheme.style,
            theme.textButtonTheme.style,
            theme.segmentedButtonTheme.style,
          ]) {
            expect(style!.shape!.resolve(const {}), isA<StadiumBorder>());
          }
        });
      });

      group('segmented buttons', () {
        final style = theme.segmentedButtonTheme.style!;

        test('the selected segment is a container pill', () {
          expect(
            style.backgroundColor!.resolve(_selected),
            scheme.primaryContainer,
          );
          expect(
            style.foregroundColor!.resolve(_selected),
            scheme.onPrimaryContainer,
          );
        });

        test('the others rest on a quiet surface', () {
          expect(
            style.backgroundColor!.resolve(const {}),
            scheme.surfaceContainer,
          );
          expect(
            style.foregroundColor!.resolve(const {}),
            scheme.onSurfaceVariant,
          );
        });

        test('both states are readable', () {
          for (final states in [_selected, const <WidgetState>{}]) {
            expect(
              _contrast(
                style.foregroundColor!.resolve(states)!,
                style.backgroundColor!.resolve(states)!,
              ),
              greaterThanOrEqualTo(4.5),
              reason: '$states',
            );
          }
        });

        test('the selected label is bolder and no smaller than 12px', () {
          final on = style.textStyle!.resolve(_selected)!;
          final off = style.textStyle!.resolve(const {})!;

          expect(on.fontWeight, FontWeight.w700);
          expect(off.fontWeight, FontWeight.w600);
          expect(on.fontSize, greaterThanOrEqualTo(12));
          expect(off.fontSize, greaterThanOrEqualTo(12));
        });

        test('is compact, with room around the label', () {
          expect(style.visualDensity, VisualDensity.compact);
          expect(style.minimumSize!.resolve(const {}), const Size(64, 40));
          expect(
            style.padding!.resolve(const {}),
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          );
        });
      });

      group('navigation bar', () {
        final bar = theme.navigationBarTheme;

        test('always shows its labels on a pill indicator', () {
          expect(
            bar.labelBehavior,
            NavigationDestinationLabelBehavior.alwaysShow,
          );
          expect(bar.indicatorShape, isA<StadiumBorder>());
          expect(bar.indicatorColor, scheme.primaryContainer);
          expect(bar.height, 76);
        });

        test('the selected destination is darker and bolder', () {
          final on = bar.labelTextStyle!.resolve(_selected)!;
          final off = bar.labelTextStyle!.resolve(const {})!;

          expect(on.fontWeight, FontWeight.w700);
          expect(off.fontWeight, FontWeight.w600);
          expect(on.color, scheme.onPrimaryContainer);
          expect(off.color, scheme.onSurfaceVariant);
          expect(
            bar.iconTheme!.resolve(_selected)!.color,
            scheme.onPrimaryContainer,
          );
          expect(
            bar.iconTheme!.resolve(const {})!.color,
            scheme.onSurfaceVariant,
          );
        });

        test('labels are never smaller than 12px', () {
          expect(
            bar.labelTextStyle!.resolve(const {})!.fontSize,
            greaterThanOrEqualTo(12),
          );
        });

        test('labels and icons are readable on their surfaces', () {
          expect(
            _contrast(scheme.onPrimaryContainer, scheme.primaryContainer),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(scheme.onSurfaceVariant, bar.backgroundColor!),
            greaterThanOrEqualTo(4.5),
          );
        });
      });

      group('tabs', () {
        final tabs = theme.tabBarTheme;

        test('the selected tab is a primary pill', () {
          expect(tabs.indicatorSize, TabBarIndicatorSize.tab);
          expect((tabs.indicator! as BoxDecoration).color, scheme.primary);
          expect(
            (tabs.indicator! as BoxDecoration).borderRadius,
            BorderRadius.circular(AppRadius.pill),
          );
          expect(tabs.dividerHeight, 0);
        });

        test('labels read on the pill and on the page', () {
          expect(tabs.labelColor, scheme.onPrimary);
          expect(tabs.unselectedLabelColor, scheme.onSurface);
          expect(
            _contrast(tabs.labelColor!, scheme.primary),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(tabs.unselectedLabelColor!, scheme.surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(tabs.labelStyle!.fontSize, greaterThanOrEqualTo(12));
        });

        test('the selected label is bolder than the rest', () {
          expect(
            tabs.labelStyle!.fontWeight!.value,
            greaterThan(tabs.unselectedLabelStyle!.fontWeight!.value),
          );
        });

        test('focus is stronger than hover', () {
          final focus = tabs.overlayColor!.resolve(_focused)!;
          final hover = tabs.overlayColor!.resolve(const {})!;

          expect(focus.a, greaterThan(hover.a));
        });
      });

      group('chips', () {
        final chip = theme.chipTheme;

        test('are pills with a checkmark when selected', () {
          expect(chip.shape, isA<StadiumBorder>());
          expect(chip.showCheckmark, isTrue);
          expect(chip.selectedColor, scheme.primary);
          expect(chip.checkmarkColor, scheme.onPrimary);
        });

        test('labels read in every state', () {
          final states = {
            'selected': (_selected, scheme.primary),
            'resting': (const <WidgetState>{}, chip.backgroundColor!),
            'disabled': (_disabled, chip.disabledColor!),
          };

          for (final state in states.entries) {
            final style = chip.labelStyle! as WidgetStateTextStyle;
            final text = style.resolve(state.value.$1);
            expect(
              _contrast(text.color!, state.value.$2),
              greaterThanOrEqualTo(4.5),
              reason: state.key,
            );
            expect(text.fontSize, greaterThanOrEqualTo(12), reason: state.key);
          }
        });

        test('the selected label is bolder', () {
          final style = chip.labelStyle! as WidgetStateTextStyle;

          expect(
            style.resolve(_selected).fontWeight!.value,
            greaterThan(style.resolve(const {}).fontWeight!.value),
          );
        });
      });

      group('surfaces', () {
        test('sheets round their top corners and show a drag handle', () {
          final sheet = theme.bottomSheetTheme;

          expect(sheet.showDragHandle, isTrue);
          expect(sheet.dragHandleSize, const Size(40, 4));
          expect(sheet.dragHandleColor, scheme.outline);
          expect(sheet.backgroundColor, scheme.surfaceContainerLow);
          expect(sheet.modalBackgroundColor, scheme.surfaceContainerLow);
          expect(
            (sheet.shape! as RoundedRectangleBorder).borderRadius,
            const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          );
        });

        test('dialogs, menus and snack bars use their own radii', () {
          expect(
            (theme.dialogTheme.shape! as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(AppRadius.hero),
          );
          expect(
            (theme.popupMenuTheme.shape! as RoundedRectangleBorder)
                .borderRadius,
            BorderRadius.circular(AppRadius.lg),
          );
          expect(
            (theme.snackBarTheme.shape! as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(AppRadius.lg),
          );
          expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
        });

        test('nothing is tinted by surface elevation', () {
          expect(theme.bottomSheetTheme.surfaceTintColor, Colors.transparent);
          expect(theme.dialogTheme.surfaceTintColor, Colors.transparent);
          expect(theme.popupMenuTheme.surfaceTintColor, Colors.transparent);
          expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
        });

        test('inputs are filled with rounded borders', () {
          final input = theme.inputDecorationTheme;

          expect(input.filled, isTrue);
          expect(input.fillColor, scheme.surfaceContainerLow);
          expect(
            (input.border! as OutlineInputBorder).borderRadius,
            BorderRadius.circular(AppRadius.md),
          );
        });

        test('input borders are visible against the page', () {
          final border =
              (theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder)
                  .borderSide
                  .color;

          expect(_contrast(border, scheme.surface), greaterThanOrEqualTo(3));
        });
      });

      group('page chrome', () {
        test('the app bar is flat, 64px and left aligned', () {
          final bar = theme.appBarTheme;

          expect(bar.toolbarHeight, 64);
          expect(bar.centerTitle, isFalse);
          expect(bar.elevation, 0);
          expect(bar.scrolledUnderElevation, 0);
          expect(bar.backgroundColor, scheme.surface);
          expect(bar.foregroundColor, scheme.onSurface);
          expect(bar.titleTextStyle!.fontWeight, FontWeight.w700);
        });

        test('progress bars are 8px on a quiet track', () {
          final progress = theme.progressIndicatorTheme;

          expect(progress.color, scheme.primary);
          expect(progress.linearMinHeight, 8);
          expect(progress.linearTrackColor, scheme.surfaceContainerHigh);
        });

        test('the page and dividers use the scheme', () {
          expect(theme.scaffoldBackgroundColor, scheme.surface);
          expect(theme.dividerTheme.color, scheme.outlineVariant);
          expect(theme.listTileTheme.iconColor, scheme.onSurfaceVariant);
        });

        test('is a Material 3 theme in the brand font', () {
          expect(theme.useMaterial3, isTrue);
          expect(theme.textTheme.bodyMedium!.fontFamily, contains('Figtree'));
        });
      });
    });
  }
}
