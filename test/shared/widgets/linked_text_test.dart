import 'package:animal/shared/widgets/linked_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _show(WidgetTester tester, String text, {int? maxLines}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LinkedText(text, maxLines: maxLines)),
      ),
    );

List<TextSpan> _spans(WidgetTester tester) {
  final root = tester.widget<RichText>(find.byType(RichText).first).text;
  final content = (root as TextSpan).children!.single as TextSpan;
  return content.children!.cast<TextSpan>();
}

void _mockLauncher(WidgetTester tester, Object? Function(MethodCall) handler) {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (call) async => handler(call),
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    ),
  );
}

Future<void> _tap(WidgetTester tester, String link) async {
  final span = _spans(tester).firstWhere((s) => s.text == link);
  (span.recognizer! as TapGestureRecognizer).onTap!();
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('underlines a link in the primary colour', (tester) async {
    await _show(tester, 'More at https://example.com today');
    final scheme = Theme.of(tester.element(find.byType(LinkedText)))
        .colorScheme;

    final spans = _spans(tester);
    expect(spans.map((s) => s.text), [
      'More at ',
      'https://example.com',
      ' today',
    ]);
    expect(spans[0].recognizer, isNull);
    expect(spans[1].recognizer, isA<TapGestureRecognizer>());
    expect(spans[1].style?.color, scheme.primary);
    expect(spans[1].style?.decoration, TextDecoration.underline);
    expect(spans[2].recognizer, isNull);
  });

  testWidgets('plain text has no tappable span', (tester) async {
    await _show(tester, 'No links here');

    expect(_spans(tester).single.recognizer, isNull);
  });

  testWidgets('tapping a link opens it in the external browser', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    _mockLauncher(tester, (call) {
      calls.add(call);
      return true;
    });
    await _show(tester, 'Go to https://example.com');

    await _tap(tester, 'https://example.com');

    expect(calls.single.method, 'launch');
    final args = calls.single.arguments as Map<Object?, Object?>;
    expect(args['url'], 'https://example.com');
    expect(args['useSafariVC'], false);
    expect(args['useWebView'], false);
    expect(find.text('Could not open the link'), findsNothing);
  });

  testWidgets('tapping a link that cannot open says so', (tester) async {
    _mockLauncher(tester, (_) => false);
    await _show(tester, 'Go to https://example.com');

    await _tap(tester, 'https://example.com');

    expect(find.text('Could not open the link'), findsOneWidget);
  });

  testWidgets('follows a changed text', (tester) async {
    await _show(tester, 'https://a.io');
    await _show(tester, 'plain now');

    expect(_spans(tester).single.text, 'plain now');
    expect(_spans(tester).single.recognizer, isNull);
  });
}
