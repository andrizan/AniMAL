import 'package:animal/shared/providers/theme_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> start([
    Map<String, Object> stored = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(stored);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(themeModeProvider, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return container;
  }

  Future<String?> saved() async =>
      (await SharedPreferences.getInstance()).getString('theme_mode');

  ThemeMode mode(ProviderContainer c) => c.read(themeModeProvider);
  ThemeModeNotifier notifier(ProviderContainer c) =>
      c.read(themeModeProvider.notifier);

  test('starts dark on a fresh install', () async {
    final c = await start();

    expect(mode(c), ThemeMode.dark);
    expect(await saved(), isNull);
  });

  test('restores a saved light theme', () async {
    final c = await start({'theme_mode': 'light'});

    expect(mode(c), ThemeMode.light);
  });

  test('restores a saved dark theme', () async {
    final c = await start({'theme_mode': 'dark'});

    expect(mode(c), ThemeMode.dark);
  });

  test('ignores a corrupted saved value', () async {
    final c = await start({'theme_mode': 'purple'});

    expect(mode(c), ThemeMode.dark);
  });

  test(
    'toggle flips between dark and light and persists each choice',
    () async {
      final c = await start();

      notifier(c).toggle();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(mode(c), ThemeMode.light);
      expect(await saved(), 'light');

      notifier(c).toggle();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(mode(c), ThemeMode.dark);
      expect(await saved(), 'dark');
    },
  );

  test('setThemeMode applies immediately and persists the name', () async {
    final c = await start();

    notifier(c).setThemeMode(ThemeMode.light);
    expect(mode(c), ThemeMode.light);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(await saved(), 'light');
  });
}
