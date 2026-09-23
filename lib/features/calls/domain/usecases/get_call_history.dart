import '../entities/call_entity.dart';
import '../repositories/call_repository.dart';

class GetCallHistory {
  final CallRepository repository;

  GetCallHistory(this.repository);

  Stream<List<CallEntity>> call(String currentUserId) {
    return repository.getCallHistoryStream(currentUserId);
  }
}
