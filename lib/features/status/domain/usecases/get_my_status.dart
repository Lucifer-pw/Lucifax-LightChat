import '../entities/user_status_group.dart';
import '../repositories/status_repository.dart';

class GetMyStatus {
  final StatusRepository repository;

  GetMyStatus(this.repository);

  Stream<UserStatusGroup?> call(String currentUserId) {
    return repository.getMyStatus(currentUserId);
  }
}
