const _callbackPath = '/oauth/callback';

String? oauthCallbackLocation(Uri uri) {
  if (uri.scheme != 'animal' ||
      uri.host != 'oauth' ||
      uri.path != '/callback') {
    return null;
  }
  final code = uri.queryParameters['code'];
  final state = uri.queryParameters['state'];
  final params = <String, String>{
    if (code != null) 'code': code,
    if (state != null) 'state': state,
  };
  return Uri(
    path: _callbackPath,
    queryParameters: params.isEmpty ? null : params,
  ).toString();
}

const _malHosts = {'myanimelist.net', 'www.myanimelist.net'};

int? malAnimeId(Uri uri) {
  if ((uri.scheme != 'https' && uri.scheme != 'http') ||
      !_malHosts.contains(uri.host)) {
    return null;
  }
  final segments = uri.pathSegments;
  if (segments.length < 2 || segments[0] != 'anime') return null;
  final id = int.tryParse(segments[1]);
  return id != null && id > 0 ? id : null;
}
