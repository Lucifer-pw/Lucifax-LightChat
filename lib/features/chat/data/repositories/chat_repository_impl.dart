import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<ChatEntity>> getChatsStream({
    required String userId,
    required String type,
  }) {
    return remoteDataSource.getChatsStream(userId: userId, type: type);
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream(String chatId) {
    return remoteDataSource.getMessagesStream(chatId);
  }

  @override
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? mediaInfo,
    Map<String, dynamic>? replyTo,
  }) async {
    try {
      final message = await remoteDataSource.sendMessage(
        chatId: chatId,
        content: content,
        type: type,
        mediaInfo: mediaInfo,
        replyTo: replyTo,
      );
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      await remoteDataSource.markAsRead(
        chatId: chatId,
        currentUserId: currentUserId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> createOrGetPrivateChat({
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
  }) async {
    try {
      final chat = await remoteDataSource.createOrGetPrivateChat(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        otherUserPhoto: otherUserPhoto,
      );
      return Right(chat);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatEntity>> createGroupChat({
    required String name,
    required String currentUserId,
    required List<String> participantIds,
    String? photoUrl,
    String? description,
  }) async {
    try {
      final chat = await remoteDataSource.createGroupChat(
        name: name,
        currentUserId: currentUserId,
        participantIds: participantIds,
        photoUrl: photoUrl,
        description: description,
      );
      return Right(chat);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadChatMedia({
    required String chatId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final url = await remoteDataSource.uploadChatMedia(
        chatId: chatId,
        filePath: filePath,
        fileName: fileName,
      );
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage({
    required String chatId,
    required String messageId,
    required String currentUserId,
    required bool forEveryone,
  }) async {
    try {
      await remoteDataSource.deleteMessage(
        chatId: chatId,
        messageId: messageId,
        currentUserId: currentUserId,
        forEveryone: forEveryone,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await remoteDataSource.setTypingStatus(
        chatId: chatId,
        userId: userId,
        isTyping: isTyping,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
