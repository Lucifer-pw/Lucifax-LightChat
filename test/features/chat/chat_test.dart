import 'package:flutter_test/flutter_test.dart';
import 'package:lucifax_lightchat/features/chat/data/models/chat_model.dart';
import 'package:lucifax_lightchat/features/chat/data/models/message_model.dart';

void main() {
  group('ChatModel', () {
    test('Correctly serializes and deserializes private chat', () {
      final json = {
        'type': 'private',
        'participants': ['user1', 'user2'],
        'participantDetails': {
          'user1': {'name': 'Alice', 'photoUrl': null},
          'user2': {'name': 'Bob', 'photoUrl': null},
        },
        'unreadCount': {'user1': 0, 'user2': 1},
        'typingUsers': ['user1'],
      };

      final model = ChatModel.fromJson(json, 'chat123');
      expect(model.chatId, 'chat123');
      expect(model.type, 'private');
      expect(model.isGroup, false);
      expect(model.participants.length, 2);
      expect(model.getDisplayName('user1'), 'Bob');
      expect(model.getDisplayName('user2'), 'Alice');
      expect(model.getUnreadCount('user2'), 1);
    });

    test('Correctly identifies and displays group chat', () {
      final json = {
        'type': 'group',
        'participants': ['user1', 'user2', 'user3'],
        'participantDetails': {
          'user1': {'name': 'Alice'},
          'user2': {'name': 'Bob'},
          'user3': {'name': 'Charlie'},
        },
        'groupInfo': {
          'name': 'Dev Team',
          'description': 'Main developers room',
          'admins': ['user1'],
          'createdBy': 'user1',
        },
        'unreadCount': {'user1': 0, 'user2': 3},
      };

      final model = ChatModel.fromJson(json, 'group456');
      expect(model.isGroup, true);
      expect(model.getDisplayName('user1'), 'Dev Team');
      expect(model.getDisplayName('user2'), 'Dev Team');
    });
  });

  group('MessageModel', () {
    test('Correctly parses text and media messages', () {
      final textJson = {
        'chatId': 'chat1',
        'senderId': 'user1',
        'senderName': 'Alice',
        'type': 'text',
        'content': 'Hello world',
        'status': 'sent',
      };

      final textMsg = MessageModel.fromJson(textJson, 'msg1');
      expect(textMsg.isSentByMe('user1'), true);
      expect(textMsg.isSentByMe('user2'), false);
      expect(textMsg.type, 'text');
      expect(textMsg.content, 'Hello world');

      final mediaJson = {
        'chatId': 'chat1',
        'senderId': 'user2',
        'senderName': 'Bob',
        'type': 'image',
        'content': 'https://firebasestorage.googleapis.com/.../photo.jpg',
        'mediaInfo': {'fileName': 'photo.jpg', 'caption': 'Look at this!'},
        'status': 'delivered',
      };

      final mediaMsg = MessageModel.fromJson(mediaJson, 'msg2');
      expect(mediaMsg.type, 'image');
      expect(mediaMsg.mediaInfo?['caption'], 'Look at this!');
    });
  });
}
