import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class CreateGroupChat {
  final ChatRepository repository;

  CreateGroupChat(this.repository);

  Future<Either<Failure, ChatEntity>> call({
    required String name,
    required String currentUserId,
    required List<String> participantIds,
    String? photoUrl,
    String? description,
  }) {
    return repository.createGroupChat(
      name: name,
      currentUserId: currentUserId,
      participantIds: participantIds,
      photoUrl: photoUrl,
      description: description,
    );
  }
}
