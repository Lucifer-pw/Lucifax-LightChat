import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

class PurgeStorageMedia {
  final ChatRepository repository;

  PurgeStorageMedia(this.repository);

  Future<Either<Failure, void>> call({
    required String chatId,
    required String messageId,
    required String storagePath,
  }) {
    return repository.purgeStorageMedia(
      chatId: chatId,
      messageId: messageId,
      storagePath: storagePath,
    );
  }
}
