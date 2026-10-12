import 'package:animal/core/utils/link_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('splitLinks', () {
    test('returns one plain run when there is no link', () {
      expect(splitLinks('Just text.'), [(text: 'Just text.', url: null)]);
    });

    test('finds a bare address between plain runs', () {
      expect(splitLinks('See https://example.com/a?b=1 now'), [
        (text: 'See ', url: null),
        (text: 'https://example.com/a?b=1', url: 'https://example.com/a?b=1'),
        (text: ' now', url: null),
      ]);
    });

    test('leaves sentence punctuation outside the link', () {
      expect(splitLinks('Visit https://example.com, or https://a.io/x.'), [
        (text: 'Visit ', url: null),
        (text: 'https://example.com', url: 'https://example.com'),
        (text: ', or ', url: null),
        (text: 'https://a.io/x', url: 'https://a.io/x'),
        (text: '.', url: null),
      ]);
    });

    test('keeps balanced parentheses and drops a closing one', () {
      expect(splitLinks('https://en.wikipedia.org/wiki/A_(B)'), [
        (
          text: 'https://en.wikipedia.org/wiki/A_(B)',
          url: 'https://en.wikipedia.org/wiki/A_(B)',
        ),
      ]);
      expect(splitLinks('(see https://example.com)'), [
        (text: '(see ', url: null),
        (text: 'https://example.com', url: 'https://example.com'),
        (text: ')', url: null),
      ]);
    });

    test('shows the label of a markdown link', () {
      expect(splitLinks('Read [the wiki](https://example.com/w) first'), [
        (text: 'Read ', url: null),
        (text: 'the wiki', url: 'https://example.com/w'),
        (text: ' first', url: null),
      ]);
    });

    test('ignores other schemes', () {
      expect(splitLinks('mailto:a@b.c and ftp://x.y'), [
        (text: 'mailto:a@b.c and ftp://x.y', url: null),
      ]);
    });
  });
}
