import 'package:animal/core/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('copyWith', () {
    test('replaces only the named colours', () {
      const replacement = Color(0xFF123456);

      final copy = AppColors.lightStatus.copyWith(
        listDropped: replacement,
      ) as StatusColors;

      expect(copy.listDropped, replacement);
      expect(copy.listWatching, AppColors.lightStatus.listWatching);
      expect(copy.droppedContainer, AppColors.lightStatus.droppedContainer);
      expect(copy.onPlanContainer, AppColors.lightStatus.onPlanContainer);
    });

    test('without arguments is an equal-looking copy', () {
      final copy = AppColors.darkStatus.copyWith() as StatusColors;

      expect(copy.star, AppColors.darkStatus.star);
      expect(copy.airingContainer, AppColors.darkStatus.airingContainer);
      expect(
        copy.onUpcomingContainer,
        AppColors.darkStatus.onUpcomingContainer,
      );
    });
  });

  group('lerp', () {
    test('is the start at 0 and the end at 1', () {
      final start =
          AppColors.lightStatus.lerp(AppColors.darkStatus, 0) as StatusColors;
      final end =
          AppColors.lightStatus.lerp(AppColors.darkStatus, 1) as StatusColors;

      expect(start.listWatching, AppColors.lightStatus.listWatching);
      expect(start.onPlanContainer, AppColors.lightStatus.onPlanContainer);
      expect(end.listWatching, AppColors.darkStatus.listWatching);
      expect(end.onPlanContainer, AppColors.darkStatus.onPlanContainer);
    });

    test('blends every colour halfway', () {
      final mid =
          AppColors.lightStatus.lerp(AppColors.darkStatus, 0.5) as StatusColors;

      expect(
        mid.star,
        Color.lerp(AppColors.lightStatus.star, AppColors.darkStatus.star, 0.5),
      );
      expect(
        mid.droppedContainer,
        Color.lerp(
          AppColors.lightStatus.droppedContainer,
          AppColors.darkStatus.droppedContainer,
          0.5,
        ),
      );
    });

    test('keeps itself when the other extension is not StatusColors', () {
      expect(
        identical(AppColors.lightStatus.lerp(null, 0.5), AppColors.lightStatus),
        isTrue,
      );
    });
  });

  group('of', () {
    Future<StatusColors> read(WidgetTester tester, ThemeData? theme) async {
      late StatusColors found;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              found = StatusColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return found;
    }

    testWidgets('returns the installed extension', (tester) async {
      final custom = AppColors.lightStatus.copyWith(
        star: const Color(0xFF010203),
      ) as StatusColors;

      final found = await read(tester, ThemeData(extensions: [custom]));

      expect(found.star, const Color(0xFF010203));
    });

    testWidgets('falls back to the light palette on a light theme', (
      tester,
    ) async {
      final found = await read(tester, ThemeData(brightness: Brightness.light));

      expect(found.airingContainer, AppColors.lightStatus.airingContainer);
    });

    testWidgets('falls back to the dark palette on a dark theme', (
      tester,
    ) async {
      final found = await read(tester, ThemeData(brightness: Brightness.dark));

      expect(found.airingContainer, AppColors.darkStatus.airingContainer);
    });
  });
}
