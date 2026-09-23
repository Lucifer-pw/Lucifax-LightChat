import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_update_info.dart';
import '../../domain/repositories/update_repository.dart';
import '../datasources/github_release_datasource.dart';

class UpdateRepositoryImpl implements UpdateRepository {
  final GithubReleaseDataSource dataSource;
  final Dio _dio;

  UpdateRepositoryImpl({
    required this.dataSource,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  @override
  Future<Either<Failure, AppUpdateInfo>> checkForUpdate() async {
    try {
      final updateInfo = await dataSource.fetchLatestRelease();
      return Right(updateInfo);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> downloadAndInstallApk(
    String downloadUrl,
    void Function(int received, int total) onProgress,
  ) async {
    try {
      Directory dir;
      try {
        dir = await getExternalStorageDirectory() ??
            await getApplicationSupportDirectory();
      } catch (_) {
        dir = await getTemporaryDirectory();
      }

      final savePath = '${dir.path}/LightChat_update.apk';

      // Delete existing file if present
      final file = File(savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
        ),
      );

      // Verify downloaded file size
      if (!await file.exists() || (await file.length()) == 0) {
        return Left(ServerFailure('Berkas unduhan kosong atau gagal disimpan.'));
      }

      // Trigger package installer
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type == ResultType.done) {
        return const Right('Installer launched');
      } else {
        return Left(ServerFailure(
            'Gagal membuka installer: ${result.message.isNotEmpty ? result.message : "Izin instalasi tidak diberikan"}'));
      }
    } catch (e) {
      return Left(ServerFailure('Gagal mengunduh pembaruan: $e'));
    }
  }
}
