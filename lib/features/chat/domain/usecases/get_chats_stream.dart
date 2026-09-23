import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class GetChatsStream {
  final ChatRepository repository;
  GetChatsStream(this.repository);

  Stream<List<ChatEntity>> call({required String userId, required String type}) {
    return repository.getChatsStream(userId: userId, type: type);
  }
}
