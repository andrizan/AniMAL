import 'package:flutter/services.dart';

const _channel = MethodChannel('com.andrizan.animal/link_settings');

/// Opens Android's "Open by default" page for this app, where
/// myanimelist.net links can be allowed to open here. Falls back to the app's
/// details page. Returns false when nothing could be opened.
Future<bool> openLinkSettings() async {
  try {
    return await _channel.invokeMethod<bool>('open') ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
