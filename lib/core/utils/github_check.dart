import 'package:animal/core/config/env.dart';
import 'package:dio/dio.dart';

/// Checks GitHub releases for the latest version.
///
/// Returns the parsed JSON response or null on failure.
Future<Map<String, dynamic>?> fetchLatestRelease() async {
  try {
    final dio = Dio();
    final response = await dio.get<Map<String, dynamic>>(
      Env.githubReleasesUrl(Env.githubRepo),
    );
    return response.data;
  } catch (_) {
    return null;
  }
}
