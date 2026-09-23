import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

class MarkAsRead {
  final ChatRepository repository;
  MarkAsRead(this.repository);

  Future<Either<Failure, void>> call({
    required String chatId,
    required String currentUserId,
  }) {
    return repository.markAsRead(
      chatId: chatId,
      currentUserId: currentUserId,
    );
  }
}
