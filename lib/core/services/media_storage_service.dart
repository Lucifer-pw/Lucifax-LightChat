import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class MediaStorageService {
  final Dio _dio;

  MediaStorageService({Dio? dio}) : _dio = dio ?? Dio();

  /// Gets the base LightChat internal-media directory
  Future<Directory> _getBaseMediaDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory('${appDir.path}/LightChat/Media');
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    return baseDir;
  }

  /// Gets specific media directory by type ('image', 'file', 'audio', 'video')
  Future<Directory> getMediaDir(String type) async {
    final base = await _getBaseMediaDir();
    String subFolder;
    switch (type.toLowerCase()) {
      case 'image':
        subFolder = 'LightChat Images';
        break;
      case 'audio':
      case 'voice':
        subFolder = 'LightChat Audio';
        break;
      case 'video':
        subFolder = 'LightChat Videos';
        break;
      case 'file':
      default:
        subFolder = 'LightChat Documents';
        break;
    }
    final dir = Directory('${base.path}/$subFolder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Checks if a file exists locally in the designated folder
  Future<String?> findLocalFile(String fileName, String type) async {
    try {
      final dir = await getMediaDir(type);
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  /// Saves a sent media file into local internal-media storage
  Future<File> saveSentMedia({
    required String sourceFilePath,
    required String targetFileName,
    required String type,
  }) async {
    final dir = await getMediaDir(type);
    final targetPath = '${dir.path}/$targetFileName';
    final sourceFile = File(sourceFilePath);
    return await sourceFile.copy(targetPath);
  }

  /// Downloads an ephemeral media file from gateway URL to internal-media storage
  Future<File?> downloadMedia({
    required String url,
    required String targetFileName,
    required String type,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final dir = await getMediaDir(type);
      final targetPath = '${dir.path}/$targetFileName';
      final targetFile = File(targetPath);

      if (await targetFile.exists()) {
        return targetFile;
      }

      await _dio.download(
        url,
        targetPath,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      if (await targetFile.exists()) {
        return targetFile;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Helper to format byte size to human readable string
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
