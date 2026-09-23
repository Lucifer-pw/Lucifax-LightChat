import 'package:equatable/equatable.dart';

class ChatEntity extends Equatable {
  final String chatId;
  final String type; // "private" | "group"
  final List<String> participants;
  final Map<String, dynamic> participantDetails; // {uid: {name, photoUrl, isOnline, lastSeen}}
  final Map<String, dynamic>? groupInfo;
  final Map<String, dynamic>? lastMessage;
  final Map<String, int> unreadCount;
  final List<String> typingUsers;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const ChatEntity({
    required this.chatId,
    required this.type,
    required this.participants,
    required this.participantDetails,
    this.groupInfo,
    this.lastMessage,
    this.unreadCount = const {},
    this.typingUsers = const [],
    this.updatedAt,
    this.createdAt,
  });

  bool get isGroup => type == 'group';

  String getDisplayName(String currentUserId) {
    if (isGroup) {
      return groupInfo?['name'] ?? 'Group Chat';
    }
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participantDetails[otherUserId]?['name'] ?? 'User';
  }

  String? getDisplayPhoto(String currentUserId) {
    if (isGroup) {
      return groupInfo?['photoUrl'];
    }
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participantDetails[otherUserId]?['photoUrl'];
  }

  bool isOtherUserOnline(String currentUserId) {
    if (isGroup) return false;
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participantDetails[otherUserId]?['isOnline'] == true;
  }

  int getUnreadCount(String currentUserId) {
    return unreadCount[currentUserId] ?? 0;
  }

  @override
  List<Object?> get props => [
        chatId,
        type,
        participants,
        participantDetails,
        groupInfo,
        lastMessage,
        unreadCount,
        typingUsers,
        updatedAt,
        createdAt,
      ];
}
