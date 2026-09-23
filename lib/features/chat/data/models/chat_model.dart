import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_entity.dart';

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.chatId,
    required super.type,
    required super.participants,
    required super.participantDetails,
    super.groupInfo,
    super.lastMessage,
    super.unreadCount,
    super.typingUsers,
    super.updatedAt,
    super.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    Map<String, int> parseUnreadCount(dynamic map) {
      if (map is Map) {
        return map.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
      return {};
    }

    return ChatModel(
      chatId: id,
      type: json['type'] ?? 'private',
      participants: (json['participants'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      participantDetails: json['participantDetails'] != null
          ? Map<String, dynamic>.from(json['participantDetails'])
          : {},
      groupInfo: json['groupInfo'] != null ? Map<String, dynamic>.from(json['groupInfo']) : null,
      lastMessage: json['lastMessage'] != null ? Map<String, dynamic>.from(json['lastMessage']) : null,
      unreadCount: parseUnreadCount(json['unreadCount']),
      typingUsers: (json['typingUsers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      updatedAt: parseDate(json['updatedAt']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  factory ChatModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatModel.fromJson(data, doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'participants': participants,
      'participantDetails': participantDetails,
      'groupInfo': groupInfo,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'typingUsers': typingUsers,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
