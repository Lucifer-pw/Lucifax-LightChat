import '../entities/user_status_group.dart';
import '../repositories/status_repository.dart';

class GetRecentStatuses {
  final StatusRepository repository;

  GetRecentStatuses(this.repository);

  Stream<List<UserStatusGroup>> call(String currentUserId) {
    return repository.getRecentStatuses(currentUserId);
  }
}
