import '../entities/call_entity.dart';
import '../repositories/call_repository.dart';

class GetIncomingCallsStream {
  final CallRepository repository;

  GetIncomingCallsStream(this.repository);

  Stream<List<CallEntity>> call(String currentUserId) {
    return repository.getIncomingCallsStream(currentUserId);
  }
}
