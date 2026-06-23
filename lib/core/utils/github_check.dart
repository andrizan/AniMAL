import 'package:animal/core/config/env.dart';
import 'package:animal/core/logger/app_logger.dart';
import 'package:dio/dio.dart';

/// Checks GitHub releases for the latest version.
///
/// Returns the parsed JSON response or null on failure.
Future<Map<String, dynamic>?> fetchLatestRelease() async {
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    final response = await dio.get<Map<String, dynamic>>(
      Env.githubReleasesUrl(Env.githubRepo),
    );
    return response.data;
  } on DioException catch (e) {
    appLogger.w('GitHub release check failed', error: e);
    return null;
  } on Exception catch (e) {
    appLogger.w('GitHub release check failed', error: e);
    return null;
  }
}
