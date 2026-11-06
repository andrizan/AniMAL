import 'package:animal/core/utils/link_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('com.andrizan.animal/link_settings');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void answer(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, handler);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null),
    );
  }

  test('asks the platform to open the settings and reports success', () async {
    final calls = <String>[];
    answer((call) async {
      calls.add(call.method);
      return true;
    });

    expect(await openLinkSettings(), isTrue);
    expect(calls, ['open']);
  });

  test('is false when the platform could open nothing', () async {
    answer((_) async => false);

    expect(await openLinkSettings(), isFalse);
  });

  test('is false when the platform gives no answer', () async {
    answer((_) async => null);

    expect(await openLinkSettings(), isFalse);
  });

  test('is false when the platform fails', () async {
    answer((_) async => throw PlatformException(code: 'boom'));

    expect(await openLinkSettings(), isFalse);
  });

  test('is false where there is no such platform code', () async {
    expect(await openLinkSettings(), isFalse);
  });
}
