import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/app_update_info.dart';

abstract class GithubReleaseDataSource {
  Future<AppUpdateInfo> fetchLatestRelease();
}

class GithubReleaseDataSourceImpl implements GithubReleaseDataSource {
  final Dio _dio;
  static const String _apiUrl =
      'https://api.github.com/repos/Lucifer-pw/Lucifax-LightChat/releases/latest';
  static const String _webLatestUrl =
      'https://github.com/Lucifer-pw/Lucifax-LightChat/releases/latest';

  GithubReleaseDataSourceImpl({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<AppUpdateInfo> fetchLatestRelease() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // 1. Try standard GitHub REST API
    try {
      final response = await _dio.get(
        _apiUrl,
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'LightChat-App',
          },
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final rawTag = (data['tag_name'] as String? ?? '').trim();
        final tagName = rawTag.replaceAll('v', '');
        final body = data['body'] as String? ?? 'Pembaruan fitur & perbaikan bug.';

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

        apkUrl ??=
            'https://github.com/Lucifer-pw/Lucifax-LightChat/releases/download/$rawTag/LightChat_$rawTag.apk';

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
      }
    } catch (_) {
      // If REST API is rate-limited (HTTP 403) or fails, fallback to web redirect
    }

    // 2. Fallback: Query GitHub Web redirect (No Rate-Limit)
    try {
      final webResponse = await _dio.get(
        _webLatestUrl,
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final location = webResponse.headers.value('location');
      if (location != null && location.contains('/releases/tag/')) {
        final rawTag = location.split('/releases/tag/').last.trim();
        final tagName = rawTag.replaceAll('v', '');
        final hasUpdate = _isNewerVersion(currentVersion, tagName);
        final downloadUrl =
            'https://github.com/Lucifer-pw/Lucifax-LightChat/releases/download/$rawTag/LightChat_$rawTag.apk';

        return AppUpdateInfo(
          latestVersion: tagName,
          currentVersion: currentVersion,
          releaseNotes:
              'Pembaruan versi $rawTag telah tersedia dengan fitur baru dan peningkatan performa.',
          downloadUrl: downloadUrl,
          apkSize: null,
          hasUpdate: hasUpdate,
          isForceUpdate: false,
        );
      }
    } catch (_) {
      // Both attempts failed
    }

    throw ServerException(
      'Gagal memeriksa pembaruan. Pastikan koneksi internet stabil dan coba lagi.',
    );
  }

  bool _isNewerVersion(String current, String latest) {
    if (latest.isEmpty) return false;
    final currentParts =
        current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts =
        latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (var i = 0; i < 3; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final l = i < latestParts.length ? latestParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
