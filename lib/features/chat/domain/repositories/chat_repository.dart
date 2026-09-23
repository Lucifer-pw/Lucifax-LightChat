import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../entities/message_entity.dart';

abstract class ChatRepository {
  Stream<List<ChatEntity>> getChatsStream({required String userId, required String type});
  Stream<List<MessageEntity>> getMessagesStream(String chatId);
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? mediaInfo,
    Map<String, dynamic>? replyTo,
  });
  Future<Either<Failure, void>> markAsRead({
    required String chatId,
    required String currentUserId,
  });
  Future<Either<Failure, ChatEntity>> createOrGetPrivateChat({
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
  });
  Future<Either<Failure, ChatEntity>> createGroupChat({
    required String name,
    required String currentUserId,
    required List<String> participantIds,
    String? photoUrl,
    String? description,
  });
  Future<Either<Failure, String>> uploadChatMedia({
    required String chatId,
    required String filePath,
    required String fileName,
  });
  Future<Either<Failure, void>> deleteMessage({
    required String chatId,
    required String messageId,
    required String currentUserId,
    required bool forEveryone,
  });
  Future<Either<Failure, void>> setTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  });
}
