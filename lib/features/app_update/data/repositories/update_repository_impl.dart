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
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/update.apk';

      // Delete existing file if present
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: onProgress,
      );

      // Trigger package installer
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type == ResultType.done) {
        return const Right('Installer launched');
      } else {
        return Left(ServerFailure('Failed to open installer: ${result.message}'));
      }
    } catch (e) {
      return Left(ServerFailure('Failed to download update: $e'));
    }
  }
}
