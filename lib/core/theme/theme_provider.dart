import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Theme mode provider.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _storageKey = 'theme_mode';
  final _storage = const FlutterSecureStorage();

  @override
  ThemeMode build() {
    unawaited(_loadTheme());
    return ThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    final saved = await _storage.read(key: _storageKey);
    if (saved != null) {
      state = switch (saved) {
        'light' => ThemeMode.light,
        _ => ThemeMode.dark,
      };
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    unawaited(_storage.write(key: _storageKey, value: mode.name));
  }

  void toggle() {
    final newMode =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }
}
