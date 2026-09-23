import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class CreateOrGetPrivateChat {
  final ChatRepository repository;
  CreateOrGetPrivateChat(this.repository);

  Future<Either<Failure, ChatEntity>> call({
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
  }) {
    return repository.createOrGetPrivateChat(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserPhoto: otherUserPhoto,
    );
  }
}
