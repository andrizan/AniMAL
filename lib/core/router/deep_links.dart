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
