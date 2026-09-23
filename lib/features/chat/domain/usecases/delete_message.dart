import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

class DeleteMessage {
  final ChatRepository repository;

  DeleteMessage(this.repository);

  Future<Either<Failure, void>> call({
    required String chatId,
    required String messageId,
    required String currentUserId,
    required bool forEveryone,
  }) {
    return repository.deleteMessage(
      chatId: chatId,
      messageId: messageId,
      currentUserId: currentUserId,
      forEveryone: forEveryone,
    );
  }
}
