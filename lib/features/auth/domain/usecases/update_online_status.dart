import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class UpdateOnlineStatus {
  final AuthRepository repository;
  UpdateOnlineStatus(this.repository);

  Future<Either<Failure, void>> call(bool isOnline) {
    return repository.updateOnlineStatus(isOnline);
  }
}
