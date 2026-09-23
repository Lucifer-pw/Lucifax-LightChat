import '../entities/call_entity.dart';
import '../repositories/call_repository.dart';

class GetCallStream {
  final CallRepository repository;

  GetCallStream(this.repository);

  Stream<CallEntity?> call(String callId) {
    return repository.getCallStream(callId);
  }
}
