import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Iterable<File> _libFiles() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.endsWith('.freezed.dart'));

List<String> _offenders(RegExp pattern, {Set<String> allowed = const {}}) => [
  for (final file in _libFiles())
    if (!allowed.any(file.path.endsWith))
      for (final (i, line) in file.readAsLinesSync().indexed)
        if (pattern.hasMatch(line)) '${file.path}:${i + 1}: ${line.trim()}',
];

void main() {
  test('font sizes come from the theme text styles', () {
    final offenders = _offenders(
      RegExp(r'\bfontSize:'),
      allowed: {'app_text_styles.dart'},
    );

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('colours come from AppColors, never from Colors.* or literals', () {
    final raw = _offenders(
      RegExp(r'\bColors\.[a-zA-Z]|\bColor\(0x'),
      allowed: {'app_colors.dart'},
    );

    expect(raw, isEmpty, reason: raw.join('\n'));
  });

  test('hand-rolled error and empty columns use the shared views', () {
    final offenders = _offenders(
      RegExp(r'Icons\.error_outline'),
      allowed: {'error_view.dart', 'profile_sections.dart'},
    );

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
