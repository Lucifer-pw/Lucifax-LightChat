import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String messageId;
  final String chatId;
  final String senderId;
  final String senderName;
  final String type; // "text" | "image" | "video" | "audio" | "file" | "voice" | "music" | "system"
  final String content;
  final Map<String, dynamic>? mediaInfo;
  final Map<String, dynamic>? musicInfo;
  final Map<String, dynamic>? replyTo;
  final String status; // "sent" | "delivered" | "read"
  final Map<String, dynamic> readBy;
  final bool isDeleted;
  final List<String> deletedFor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MessageEntity({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.type = 'text',
    required this.content,
    this.mediaInfo,
    this.musicInfo,
    this.replyTo,
    this.status = 'sent',
    this.readBy = const {},
    this.isDeleted = false,
    this.deletedFor = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool isSentByMe(String currentUserId) => senderId == currentUserId;

  @override
  List<Object?> get props => [
        messageId,
        chatId,
        senderId,
        senderName,
        type,
        content,
        mediaInfo,
        musicInfo,
        replyTo,
        status,
        readBy,
        isDeleted,
        deletedFor,
        createdAt,
        updatedAt,
      ];
}
