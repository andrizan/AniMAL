import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';
const _iosSet = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

typedef _Png = ({int width, int height, int colorType});

_Png _png(String path) {
  final bytes = File(path).readAsBytesSync();
  final header = ByteData.sublistView(bytes, 0, 26);
  expect(bytes.sublist(1, 4), 'PNG'.codeUnits, reason: '$path is a PNG');
  return (
    width: header.getUint32(16),
    height: header.getUint32(20),
    colorType: header.getUint8(25),
  );
}

const _rgb = 2;
const _rgba = 6;

void main() {
  group('Android launcher icon', () {
    for (final entry in _densities.entries) {
      final dir = '$_res/mipmap-${entry.key}';
      final tile = (48 * entry.value).round();
      final layer = (108 * entry.value).round();

      test('${entry.key} has a ${tile}px icon and ${layer}px layers', () {
        final legacy = _png('$dir/ic_launcher.png');
        expect((legacy.width, legacy.height), (tile, tile));
        expect(legacy.colorType, _rgba, reason: 'rounded corners are clear');

        for (final layerName in [
          'ic_launcher_background',
          'ic_launcher_foreground',
          'ic_launcher_monochrome',
        ]) {
          final png = _png('$dir/$layerName.png');
          expect((png.width, png.height), (layer, layer), reason: layerName);
        }
      });

      test('${entry.key} background is opaque, foreground is not', () {
        expect(_png('$dir/ic_launcher_background.png').colorType, _rgb);
        expect(_png('$dir/ic_launcher_foreground.png').colorType, _rgba);
        expect(_png('$dir/ic_launcher_monochrome.png').colorType, _rgba);
      });
    }

    test('the adaptive icon uses all three layers', () {
      final xml = File('$_res/mipmap-anydpi-v26/ic_launcher.xml')
          .readAsStringSync();

      expect(xml, contains('<adaptive-icon'));
      expect(
        xml,
        contains(
          '<background android:drawable="@mipmap/ic_launcher_background"',
        ),
      );
      expect(
        xml,
        contains(
          '<foreground android:drawable="@mipmap/ic_launcher_foreground"',
        ),
      );
      expect(
        xml,
        contains(
          '<monochrome android:drawable="@mipmap/ic_launcher_monochrome"',
        ),
      );
    });

    test('the manifest points at it', () {
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        contains('android:icon="@mipmap/ic_launcher"'),
      );
    });
  });

  group('iOS app icon', () {
    final contents = jsonDecode(
      File('$_iosSet/Contents.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final images = (contents['images'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    test('lists the icons the platform asks for', () {
      expect(images, isNotEmpty);
      expect(images.any((i) => i['idiom'] == 'ios-marketing'), isTrue);
    });

    test('every listed file exists at the size it is listed with', () {
      for (final image in images) {
        final name = image['filename']! as String;
        final expected = int.parse(image['expected-size']! as String);
        final png = _png('$_iosSet/$name');

        expect((png.width, png.height), (expected, expected), reason: name);
      }
    });

    test('has no alpha channel, which the App Store rejects', () {
      for (final image in images) {
        final name = image['filename']! as String;

        expect(_png('$_iosSet/$name').colorType, _rgb, reason: name);
      }
    });

    test('the marketing icon is 1024px', () {
      final marketing = images.firstWhere((i) => i['idiom'] == 'ios-marketing');
      final png = _png('$_iosSet/${marketing['filename']}');

      expect((png.width, png.height), (1024, 1024));
    });
  });
}
