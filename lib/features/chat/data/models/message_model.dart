import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.messageId,
    required super.chatId,
    required super.senderId,
    required super.senderName,
    super.type,
    required super.content,
    super.mediaInfo,
    super.musicInfo,
    super.replyTo,
    super.status,
    super.readBy,
    super.isDeleted,
    super.deletedFor,
    super.createdAt,
    super.updatedAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return MessageModel(
      messageId: id,
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      type: json['type'] ?? 'text',
      content: json['content'] ?? '',
      mediaInfo: json['mediaInfo'] != null ? Map<String, dynamic>.from(json['mediaInfo']) : null,
      musicInfo: json['musicInfo'] != null ? Map<String, dynamic>.from(json['musicInfo']) : null,
      replyTo: json['replyTo'] != null ? Map<String, dynamic>.from(json['replyTo']) : null,
      status: json['status'] ?? 'sent',
      readBy: json['readBy'] != null ? Map<String, dynamic>.from(json['readBy']) : {},
      isDeleted: json['isDeleted'] ?? false,
      deletedFor: (json['deletedFor'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel.fromJson(data, doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'content': content,
      'mediaInfo': mediaInfo,
      'musicInfo': musicInfo,
      'replyTo': replyTo,
      'status': status,
      'readBy': readBy,
      'isDeleted': isDeleted,
      'deletedFor': deletedFor,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
