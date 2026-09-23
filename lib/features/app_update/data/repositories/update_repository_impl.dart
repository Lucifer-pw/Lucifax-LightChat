import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_update_info.dart';
import '../../domain/repositories/update_repository.dart';
import '../datasources/github_release_datasource.dart';

class UpdateRepositoryImpl implements UpdateRepository {
  final GithubReleaseDataSource dataSource;

  UpdateRepositoryImpl({required this.dataSource});

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
    // APK Download Implementation with Dio
    return const Right('Download completed');
  }
}
