import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_update_info.dart';

abstract class UpdateRepository {
  Future<Either<Failure, AppUpdateInfo>> checkForUpdate();
  Future<Either<Failure, String>> downloadAndInstallApk(
    String downloadUrl,
    void Function(int received, int total) onProgress,
  );
}
