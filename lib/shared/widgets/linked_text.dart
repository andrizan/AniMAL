import 'package:animal/core/utils/link_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// Selectable body text whose web links open in the external browser.
class LinkedText extends StatefulWidget {
  const LinkedText(this.text, {super.key, this.style, this.maxLines});

  final String text;
  final TextStyle? style;
  final int? maxLines;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  var _pieces = <({String text, TapGestureRecognizer? tap})>[];

  @override
  void initState() {
    super.initState();
    _pieces = _split();
  }

  @override
  void didUpdateWidget(LinkedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _disposeRecognizers();
      _pieces = _split();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  List<({String text, TapGestureRecognizer? tap})> _split() => [
    for (final span in splitLinks(widget.text))
      (
        text: span.text,
        tap: span.url == null
            ? null
            : (TapGestureRecognizer()..onTap = () => _open(span.url!)),
      ),
  ];

  void _disposeRecognizers() {
    for (final piece in _pieces) {
      piece.tap?.dispose();
    }
  }

  Future<void> _open(String url) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (!await openExternalUrl(url)) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final linkStyle = TextStyle(
      color: scheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: scheme.primary,
    );
    return SelectionArea(
      child: Text.rich(
        TextSpan(
          children: [
            for (final piece in _pieces)
              TextSpan(
                text: piece.text,
                recognizer: piece.tap,
                style: piece.tap == null ? null : linkStyle,
              ),
          ],
        ),
        style: widget.style,
        maxLines: widget.maxLines,
      ),
    );
  }
}
