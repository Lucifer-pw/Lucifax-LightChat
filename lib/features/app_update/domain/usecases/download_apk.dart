import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/update_repository.dart';

class DownloadAndInstallApk {
  final UpdateRepository repository;

  DownloadAndInstallApk(this.repository);

  Future<Either<Failure, String>> call(
    String downloadUrl,
    void Function(int received, int total) onProgress,
  ) {
    return repository.downloadAndInstallApk(downloadUrl, onProgress);
  }
}
