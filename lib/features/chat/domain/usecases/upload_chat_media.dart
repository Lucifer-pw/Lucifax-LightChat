import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

class UploadChatMedia {
  final ChatRepository repository;

  UploadChatMedia(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String chatId,
    required String filePath,
    required String fileName,
  }) {
    return repository.uploadChatMedia(
      chatId: chatId,
      filePath: filePath,
      fileName: fileName,
    );
  }
}
