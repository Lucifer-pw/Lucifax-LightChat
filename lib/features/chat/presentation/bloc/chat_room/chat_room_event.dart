import 'package:equatable/equatable.dart';
import '../../../domain/entities/message_entity.dart';

abstract class ChatRoomEvent extends Equatable {
  const ChatRoomEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessagesEvent extends ChatRoomEvent {
  final String chatId;
  final String currentUserId;
  const LoadMessagesEvent({required this.chatId, required this.currentUserId});

  @override
  List<Object?> get props => [chatId, currentUserId];
}

class MessagesUpdatedEvent extends ChatRoomEvent {
  final List<MessageEntity> messages;
  const MessagesUpdatedEvent(this.messages);

  @override
  List<Object?> get props => [messages];
}

class SendTextMessageEvent extends ChatRoomEvent {
  final String chatId;
  final String content;
  final Map<String, dynamic>? replyTo;
  const SendTextMessageEvent({
    required this.chatId,
    required this.content,
    this.replyTo,
  });

  @override
  List<Object?> get props => [chatId, content, replyTo];
}

class MarkChatAsReadEvent extends ChatRoomEvent {
  final String chatId;
  final String currentUserId;
  const MarkChatAsReadEvent({required this.chatId, required this.currentUserId});

  @override
  List<Object?> get props => [chatId, currentUserId];
}

class SetTypingEvent extends ChatRoomEvent {
  final String chatId;
  final String userId;
  final bool isTyping;
  const SetTypingEvent({
    required this.chatId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [chatId, userId, isTyping];
}

class SendMediaMessageEvent extends ChatRoomEvent {
  final String chatId;
  final String filePath;
  final String fileName;
  final String type; // "image" | "video" | "file" | "audio"
  final String? caption;
  final Map<String, dynamic>? replyTo;

  const SendMediaMessageEvent({
    required this.chatId,
    required this.filePath,
    required this.fileName,
    required this.type,
    this.caption,
    this.replyTo,
  });

  @override
  List<Object?> get props => [chatId, filePath, fileName, type, caption, replyTo];
}

class DeleteMessageEvent extends ChatRoomEvent {
  final String chatId;
  final String messageId;
  final String currentUserId;
  final bool forEveryone;

  const DeleteMessageEvent({
    required this.chatId,
    required this.messageId,
    required this.currentUserId,
    required this.forEveryone,
  });

  @override
  List<Object?> get props => [chatId, messageId, currentUserId, forEveryone];
}
