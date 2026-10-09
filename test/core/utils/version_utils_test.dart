import 'package:animal/core/utils/version_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNewerVersion', () {
    test('detects a newer patch, minor and major release', () {
      expect(isNewerVersion('2.9.1', '2.9.0'), isTrue);
      expect(isNewerVersion('2.10.0', '2.9.0'), isTrue);
      expect(isNewerVersion('3.0.0', '2.99.99'), isTrue);
    });

    test('compares numbers, not strings', () {
      expect(isNewerVersion('2.10.0', '2.9.9'), isTrue);
      expect(isNewerVersion('2.9.9', '2.10.0'), isFalse);
      expect(isNewerVersion('10.0.0', '9.0.0'), isTrue);
    });

    test('the same version is not an update', () {
      expect(isNewerVersion('2.9.0', '2.9.0'), isFalse);
    });

    test('an older release is not an update (no downgrade offer)', () {
      expect(isNewerVersion('2.9.0', '2.10.0'), isFalse);
      expect(isNewerVersion('2.8.0', '2.9.0'), isFalse);
    });

    test('accepts a leading v on either side', () {
      expect(isNewerVersion('v2.9.1', '2.9.0'), isTrue);
      expect(isNewerVersion('2.9.0', 'v2.9.0'), isFalse);
      expect(isNewerVersion('V2.9.1', 'v2.9.0'), isTrue);
    });

    test('treats missing trailing segments as zero', () {
      expect(isNewerVersion('2.9', '2.9.0'), isFalse);
      expect(isNewerVersion('2.9.0', '2.9'), isFalse);
      expect(isNewerVersion('2.9.1', '2.9'), isTrue);
    });

    test('ignores build metadata', () {
      expect(isNewerVersion('2.9.0+12', '2.9.0'), isFalse);
      expect(isNewerVersion('2.9.1+1', '2.9.0+99'), isTrue);
    });

    test('a pre-release is older than its final release', () {
      expect(isNewerVersion('2.9.0', '2.9.0-beta'), isTrue);
      expect(isNewerVersion('2.9.0-beta', '2.9.0'), isFalse);
      expect(isNewerVersion('2.9.0beta', '2.9.0'), isFalse);
      expect(isNewerVersion('2.9.0_rc1', '2.9.0'), isFalse);
    });

    test('orders two pre-releases of the same version', () {
      expect(isNewerVersion('2.9.0-beta2', '2.9.0-beta1'), isTrue);
      expect(isNewerVersion('2.9.0-beta1', '2.9.0-beta2'), isFalse);
    });

    test('a newer core beats any suffix', () {
      expect(isNewerVersion('2.9.1-beta', '2.9.0'), isTrue);
    });

    test('falls back to inequality for versions it cannot parse', () {
      expect(isNewerVersion('nightly', '2.9.0'), isTrue);
      expect(isNewerVersion('2.9.0', 'dev'), isTrue);
      expect(isNewerVersion('dev', 'dev'), isFalse);
    });
  });
}
