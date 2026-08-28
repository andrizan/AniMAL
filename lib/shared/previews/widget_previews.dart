/// Widget previews for the shared UI library.
///
/// Powers `flutter widget-preview start` (stable in Flutter 3.47).
/// Each top-level function must return a `Widget` and be public.
library;

import 'package:animal/core/theme/app_theme.dart';
import 'package:animal/shared/widgets/info_chip.dart';
// The @Preview annotation is not exported from a public path; this is the
// only way to access it until Flutter exposes it via a stable API.
// ignore: implementation_imports
import 'package:flutter/src/widget_previews/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

@Preview(name: 'InfoChip — basic', group: 'shared')
Widget previewInfoChip() => const InfoChip(
  label: 'TV',
  icon: Icons.tv,
);

@Preview(name: 'InfoChip — score', group: 'shared')
Widget previewInfoChipScore() => const InfoChip(
  label: '8.74',
  icon: Icons.star,
  color: Color(0xFFFFB300),
);

@Preview(
  name: 'InfoChip — light theme',
  group: 'shared',
  theme: AppPreviewTheme.light,
)
Widget previewInfoChipLight() => const InfoChip(
  label: 'Rank #12',
  icon: Icons.emoji_events,
);

@Preview(
  name: 'InfoChip — dark theme',
  group: 'shared',
  theme: AppPreviewTheme.dark,
)
Widget previewInfoChipDark() => const InfoChip(
  label: 'Airing',
  icon: Icons.live_tv,
);

final class AppPreviewTheme extends PreviewThemeData {
  const AppPreviewTheme(this._brightness);

  final Brightness _brightness;

  static PreviewThemeData light() => const AppPreviewTheme(Brightness.light);
  static PreviewThemeData dark() => const AppPreviewTheme(Brightness.dark);

  @override
  Widget apply(BuildContext context, Widget child) {
    final theme = switch (_brightness) {
      Brightness.light => buildLightTheme(),
      Brightness.dark => buildDarkTheme(),
    };
    return Theme(data: theme, child: child);
  }
}
