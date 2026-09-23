import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/app_update_info.dart';

abstract class GithubReleaseDataSource {
  Future<AppUpdateInfo> fetchLatestRelease();
}

class GithubReleaseDataSourceImpl implements GithubReleaseDataSource {
  final Dio _dio;
  static const String _repoUrl =
      'https://api.github.com/repos/Lucifer-pw/lucifax-lightchat/releases/latest';

  GithubReleaseDataSourceImpl({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<AppUpdateInfo> fetchLatestRelease() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _dio.get(
        _repoUrl,
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final tagName = (data['tag_name'] as String? ?? '').replaceAll('v', '');
        final body = data['body'] as String? ?? 'Bug fixes & performance improvements';

        String? apkUrl;
        int? apkSize;

        final assets = data['assets'] as List<dynamic>? ?? [];
        for (var asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'];
            apkSize = asset['size'];
            break;
          }
        }

        final hasUpdate = _isNewerVersion(currentVersion, tagName);

        return AppUpdateInfo(
          latestVersion: tagName,
          currentVersion: currentVersion,
          releaseNotes: body,
          downloadUrl: apkUrl,
          apkSize: apkSize,
          hasUpdate: hasUpdate,
          isForceUpdate: false,
        );
      } else {
        throw ServerException('Failed to fetch update from GitHub');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  bool _isNewerVersion(String current, String latest) {
    if (latest.isEmpty) return false;
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (var i = 0; i < 3; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final l = i < latestParts.length ? latestParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
