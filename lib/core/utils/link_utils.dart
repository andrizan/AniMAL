import 'package:animal/core/logger/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// A run of text, tappable when `url` is set.
typedef LinkSpan = ({String text, String? url});

final _linkPattern = RegExp(
  r'\[([^\]\n]+)\]\((https?://[^\s)]+)\)|https?://[^\s<>\[\]]+',
  caseSensitive: false,
);

const _trailingPunctuation = '.,;:!?\'"';

String _trimTrailing(String url) {
  var end = url.length;
  while (end > 0) {
    final last = url[end - 1];
    if (_trailingPunctuation.contains(last)) {
      end--;
    } else if (last == ')' && _unbalanced(url.substring(0, end))) {
      end--;
    } else {
      break;
    }
  }
  return url.substring(0, end);
}

bool _unbalanced(String url) =>
    ')'.allMatches(url).length > '('.allMatches(url).length;

/// Splits [text] into plain runs and web links: bare `http(s)://` addresses
/// and `[label](url)` markdown links.
List<LinkSpan> splitLinks(String text) {
  final spans = <LinkSpan>[];
  var cursor = 0;
  for (final match in _linkPattern.allMatches(text)) {
    final label = match.group(1);
    final String shown;
    final String url;
    var end = match.end;
    if (label != null) {
      shown = label;
      url = match.group(2)!;
    } else {
      shown = url = _trimTrailing(match.group(0)!);
      end = match.start + url.length;
    }
    if (match.start > cursor) {
      spans.add((text: text.substring(cursor, match.start), url: null));
    }
    spans.add((text: shown, url: url));
    cursor = end;
  }
  if (cursor < text.length) {
    spans.add((text: text.substring(cursor), url: null));
  }
  return spans;
}

/// Opens an `http(s)` [url] in the device browser. Returns false when it is
/// not a web address or nothing could open it.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return false;
  }
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception catch (e) {
    appLogger.w('Could not open $url', error: e);
    return false;
  }
}
