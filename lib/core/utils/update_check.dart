import 'package:animal/core/config/env.dart';
import 'package:animal/core/logger/app_logger.dart';
import 'package:animal/core/utils/version_utils.dart';

/// A published release newer than the installed app.
typedef AppUpdate = ({String version, String url});

/// The latest release when it is newer than the installed version, otherwise
/// null. A failed lookup is also null: a launch must never be disturbed by a
/// network error.
Future<AppUpdate?> findNewerRelease({
  required Future<Map<String, dynamic>?> Function() fetchRelease,
  required Future<String> Function() currentVersion,
}) async {
  try {
    final release = await fetchRelease();
    if (release == null) return null;

    final latest = ((release['tag_name'] as String?) ?? '').trim();
    if (!RegExp(r'^[vV]?\d').hasMatch(latest)) return null;

    final installed = await currentVersion();
    if (!isNewerVersion(latest, installed)) return null;

    final url = (release['html_url'] as String?) ?? '';
    return (
      version: latest.replaceFirst(RegExp('^[vV]'), ''),
      url: url.isEmpty ? '${Env.githubRepoUrl}/releases/latest' : url,
    );
  } on Object catch (e) {
    appLogger.w('Update check failed', error: e);
    return null;
  }
}
