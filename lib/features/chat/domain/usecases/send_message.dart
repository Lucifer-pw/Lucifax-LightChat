import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository repository;
  SendMessage(this.repository);

  Future<Either<Failure, MessageEntity>> call({
    required String chatId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? mediaInfo,
    Map<String, dynamic>? replyTo,
  }) {
    return repository.sendMessage(
      chatId: chatId,
      content: content,
      type: type,
      mediaInfo: mediaInfo,
      replyTo: replyTo,
    );
  }
}
