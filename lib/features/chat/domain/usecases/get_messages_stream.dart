import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class GetMessagesStream {
  final ChatRepository repository;
  GetMessagesStream(this.repository);

  Stream<List<MessageEntity>> call(String chatId) {
    return repository.getMessagesStream(chatId);
  }
}
