// Renders every launcher icon from `AppMarkPainter`.
//
//   flutter test tool/render_app_icon.dart
//   flutter test tool/render_app_icon.dart --dart-define=PREVIEW_DIR=<dir>
//
// With PREVIEW_DIR it only writes a contact sheet there. Without it, it
// rewrites the Android and iOS icon files in place.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:animal/core/theme/app_colors.dart';
import 'package:animal/shared/widgets/app_mark.dart';
import 'package:flutter_test/flutter_test.dart';

const _previewDir = String.fromEnvironment('PREVIEW_DIR');

const _androidRes = 'android/app/src/main/res';
const _iosSet = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

/// Share of the canvas the glyph may use inside an adaptive icon: the system
/// only guarantees the middle 66dp of the 108dp canvas.
const _adaptiveScale = 0.76;

const _density = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

void _gradient(ui.Canvas canvas, ui.Rect rect, {double radius = 0}) {
  final paint = ui.Paint()
    ..shader = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      AppColors.brandGradient,
    );
  if (radius == 0) {
    canvas.drawRect(rect, paint);
  } else {
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(radius)),
      paint,
    );
  }
}

void _glyph(
  ui.Canvas canvas,
  ui.Rect rect, {
  double scale = 1,
  ui.Color? color,
  bool monochrome = false,
}) {
  canvas
    ..save()
    ..translate(rect.left, rect.top);
  AppMarkPainter(
    scale: scale,
    glyph: color,
    monochrome: monochrome,
  ).paint(canvas, rect.size);
  canvas.restore();
}

Future<ui.Image> _draw(int px, void Function(ui.Canvas, ui.Rect) layers) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  layers(canvas, ui.Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()));
  return recorder.endRecording().toImage(px, px);
}

/// A PNG of [image]; [alpha] false writes plain RGB, as the App Store wants.
Future<Uint8List> _png(ui.Image image, {required bool alpha}) async {
  final rgba = (await image.toByteData())!.buffer.asUint8List();
  final channels = alpha ? 4 : 3;
  final raw = BytesBuilder();
  for (var y = 0; y < image.height; y++) {
    raw.addByte(0);
    for (var x = 0; x < image.width; x++) {
      final i = (y * image.width + x) * 4;
      raw
        ..addByte(rgba[i])
        ..addByte(rgba[i + 1])
        ..addByte(rgba[i + 2]);
      if (alpha) raw.addByte(rgba[i + 3]);
    }
  }
  assert(channels == (alpha ? 4 : 3));

  final out = BytesBuilder()..add([137, 80, 78, 71, 13, 10, 26, 10]);
  void chunk(String type, List<int> data) {
    final body = [...type.codeUnits, ...data];
    final length = ByteData(4)..setUint32(0, data.length);
    final crc = ByteData(4)..setUint32(0, _crc32(body));
    out
      ..add(length.buffer.asUint8List())
      ..add(body)
      ..add(crc.buffer.asUint8List());
  }

  final header = ByteData(13)
    ..setUint32(0, image.width)
    ..setUint32(4, image.height)
    ..setUint8(8, 8)
    ..setUint8(9, alpha ? 6 : 2);
  chunk('IHDR', header.buffer.asUint8List());
  chunk('IDAT', ZLibCodec(level: 9).encode(raw.toBytes()));
  chunk('IEND', const []);
  return out.toBytes();
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

Future<void> _write(String path, ui.Image image, {required bool alpha}) async {
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(await _png(image, alpha: alpha));
}

void _legacy(ui.Canvas canvas, ui.Rect r) {
  _gradient(canvas, r, radius: r.width * 0.22);
  _glyph(canvas, r, scale: 0.92);
}

void _full(ui.Canvas canvas, ui.Rect r) {
  _gradient(canvas, r);
  _glyph(canvas, r, scale: 0.92);
}

void main() {
  test('renders the launcher icons', () async {
    if (_previewDir.isNotEmpty) {
      await _preview();
      return;
    }

    for (final entry in _density.entries) {
      final dir = '$_androidRes/mipmap-${entry.key}';
      final tile = (48 * entry.value).round();
      final layer = (108 * entry.value).round();

      await _write(
        '$dir/ic_launcher.png',
        await _draw(tile, _legacy),
        alpha: true,
      );
      await _write(
        '$dir/ic_launcher_background.png',
        await _draw(layer, (c, r) => _gradient(c, r)),
        alpha: false,
      );
      await _write(
        '$dir/ic_launcher_foreground.png',
        await _draw(layer, (c, r) => _glyph(c, r, scale: _adaptiveScale)),
        alpha: true,
      );
      await _write(
        '$dir/ic_launcher_monochrome.png',
        await _draw(
          layer,
          (c, r) => _glyph(
            c,
            r,
            scale: _adaptiveScale,
            color: AppColors.markGlyph,
            monochrome: true,
          ),
        ),
        alpha: true,
      );
    }

    final sizes = Directory(_iosSet)
        .listSync()
        .map((f) => RegExp(r'^(\d+)\.png$').firstMatch(f.uri.pathSegments.last))
        .whereType<RegExpMatch>()
        .map((m) => int.parse(m.group(1)!));
    for (final px in sizes) {
      await _write('$_iosSet/$px.png', await _draw(px, _full), alpha: false);
    }
  });
}

/// One sheet with the icon at the sizes it is seen at, on light and dark.
Future<void> _preview() async {
  const width = 1500;
  const height = 760;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, width / 2, height + 0),
    ui.Paint()..color = const ui.Color(0xFFF1F0F9),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(width / 2, 0, width / 2, height + 0),
    ui.Paint()..color = const ui.Color(0xFF14121F),
  );

  void tile(
    double x,
    double y,
    double size,
    void Function(ui.Canvas, ui.Rect) draw,
  ) {
    draw(canvas, ui.Rect.fromLTWH(x, y, size, size));
  }

  // Large icon, then the sizes of a home screen, then the system masks.
  tile(30, 30, 512, _legacy);
  var x = 580.0;
  for (final size in [192.0, 144.0, 96.0, 64.0, 48.0, 32.0]) {
    tile(x, 40, size, _legacy);
    x += size + 24;
  }
  // The same sizes on the dark half.
  x = 780.0;
  for (final size in [192.0, 144.0, 96.0, 64.0, 48.0]) {
    tile(x, 300, size, _legacy);
    x += size + 24;
  }

  // Adaptive icon under a circle, a squircle-ish rounded square and a square.
  void adaptive(double x, double y, double size, double radius) {
    final rect = ui.Rect.fromLTWH(x, y, size, size);
    canvas
      ..save()
      ..clipRRect(ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(radius)));
    _gradient(canvas, rect);
    _glyph(canvas, rect, scale: _adaptiveScale);
    canvas.restore();
  }

  adaptive(30, 580, 140, 70);
  adaptive(190, 580, 140, 40);
  adaptive(350, 580, 140, 0);

  // The themed (monochrome) icon on a tinted circle, light and dark.
  void themed(double x, double y, ui.Color plate, ui.Color ink) {
    canvas.drawCircle(ui.Offset(x + 70, y + 70), 70, ui.Paint()..color = plate);
    _glyph(
      canvas,
      ui.Rect.fromLTWH(x, y, 140, 140),
      scale: _adaptiveScale,
      color: ink,
      monochrome: true,
    );
  }

  themed(780, 580, const ui.Color(0xFFD9D4FF), const ui.Color(0xFF2B2370));
  themed(960, 580, const ui.Color(0xFF3A3470), const ui.Color(0xFFE6E0FF));

  final image = await recorder.endRecording().toImage(width, height);
  await _write('$_previewDir/sheet.png', image, alpha: false);
  await _write(
    '$_previewDir/icon_1024.png',
    await _draw(1024, _legacy),
    alpha: true,
  );
}
