import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_update_info.dart';
import '../repositories/update_repository.dart';

class CheckForUpdate {
  final UpdateRepository repository;
  CheckForUpdate(this.repository);

  Future<Either<Failure, AppUpdateInfo>> call() {
    return repository.checkForUpdate();
  }
}
