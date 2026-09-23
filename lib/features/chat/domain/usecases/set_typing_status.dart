import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

class SetTypingStatus {
  final ChatRepository repository;
  SetTypingStatus(this.repository);

  Future<Either<Failure, void>> call({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) {
    return repository.setTypingStatus(
      chatId: chatId,
      userId: userId,
      isTyping: isTyping,
    );
  }
}
