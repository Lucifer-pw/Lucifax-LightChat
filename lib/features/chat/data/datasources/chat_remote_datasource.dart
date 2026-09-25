import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Stream<List<ChatModel>> getChatsStream({required String userId, required String type});
  Stream<List<MessageModel>> getMessagesStream(String chatId);
  Future<MessageModel> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? mediaInfo,
    Map<String, dynamic>? replyTo,
  });
  Future<void> markAsRead({
    required String chatId,
    required String currentUserId,
  });
  Future<ChatModel> createOrGetPrivateChat({
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
  });
  Future<ChatModel> createGroupChat({
    required String name,
    required String currentUserId,
    required List<String> participantIds,
    String? photoUrl,
    String? description,
  });
  Future<String> uploadChatMedia({
    required String chatId,
    required String filePath,
    required String fileName,
  });
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String currentUserId,
    required bool forEveryone,
  });
  Future<void> setTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final FirebaseStorage _storage;

  ChatRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Stream<List<ChatModel>> getChatsStream({
    required String userId,
    required String type,
  }) {
    // Single-field query (never requires composite index)
    return _firestore
        .collection(FirebaseConstants.chatsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs.map((doc) => ChatModel.fromDocument(doc)).toList();

      // In-memory filter by type ('private' or 'group')
      final filtered = chats.where((c) => c.type == type).toList();

      // In-memory sort by latest activity (updatedAt descending)
      filtered.sort((a, b) {
        final timeA = a.updatedAt ?? a.createdAt ?? DateTime(0);
        final timeB = b.updatedAt ?? b.createdAt ?? DateTime(0);
        return timeB.compareTo(timeA);
      });

      return filtered;
    });
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection(FirebaseConstants.chatsCollection)
        .doc(chatId)
        .collection(FirebaseConstants.messagesSubcollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromDocument(doc)).toList();
    });
  }

  @override
  Future<MessageModel> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? mediaInfo,
    Map<String, dynamic>? replyTo,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw const AuthException('User not logged in');

      // Fetch user displayName
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .get();
      final senderName = userDoc.data()?['displayName'] ?? 'User';

      final messageRef = _firestore
          .collection(FirebaseConstants.chatsCollection)
          .doc(chatId)
          .collection(FirebaseConstants.messagesSubcollection)
          .doc();

      final now = DateTime.now();

      final messageModel = MessageModel(
        messageId: messageRef.id,
        chatId: chatId,
        senderId: user.uid,
        senderName: senderName,
        type: type,
        content: content,
        mediaInfo: mediaInfo,
        replyTo: replyTo,
        status: 'sent',
        createdAt: now,
        updatedAt: now,
      );

      final batch = _firestore.batch();

      // 1. Write message
      batch.set(messageRef, messageModel.toJson());

      // 2. Update chat last message & unread count
      final chatRef = _firestore.collection(FirebaseConstants.chatsCollection).doc(chatId);
      final chatDoc = await chatRef.get();
      final participants = (chatDoc.data()?['participants'] as List<dynamic>?) ?? [];

      final unreadCountUpdate = <String, dynamic>{};
      for (var p in participants) {
        if (p != user.uid) {
          unreadCountUpdate['unreadCount.$p'] = FieldValue.increment(1);
        }
      }

      batch.update(chatRef, {
        'lastMessage': {
          'text': content,
          'senderId': user.uid,
          'senderName': senderName,
          'type': type,
          'timestamp': Timestamp.fromDate(now),
        },
        'updatedAt': FieldValue.serverTimestamp(),
        ...unreadCountUpdate,
      });

      await batch.commit();
      return messageModel;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markAsRead({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      final chatRef = _firestore.collection(FirebaseConstants.chatsCollection).doc(chatId);

      // Reset unread count for current user
      await chatRef.update({
        'unreadCount.$currentUserId': 0,
      });

      // Fetch recent messages and filter unread in memory to avoid index requirements
      final messagesSnapshot = await chatRef
          .collection(FirebaseConstants.messagesSubcollection)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final toUpdate = messagesSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['senderId'] != currentUserId && data['status'] != 'read';
      }).toList();

      if (toUpdate.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in toUpdate) {
          batch.update(doc.reference, {
            'status': 'read',
            'readBy.$currentUserId': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
    } catch (e) {
      // Best-effort
    }
  }

  @override
  Future<ChatModel> createOrGetPrivateChat({
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
  }) async {
    try {
      // Check existing private chat using simple arrayContains query
      final query = await _firestore
          .collection(FirebaseConstants.chatsCollection)
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in query.docs) {
        final data = doc.data();
        final isPrivate = (data['type'] ?? 'private') == 'private';
        final participants = (data['participants'] as List<dynamic>?) ?? [];
        if (isPrivate && participants.contains(otherUserId)) {
          return ChatModel.fromDocument(doc);
        }
      }

      // Fetch current user details
      final currentUserDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUserId)
          .get();
      final currentUserName = currentUserDoc.data()?['displayName'] ?? 'User';
      final currentUserPhoto = currentUserDoc.data()?['photoUrl'];

      final newChatRef = _firestore.collection(FirebaseConstants.chatsCollection).doc();

      final newChat = ChatModel(
        chatId: newChatRef.id,
        type: 'private',
        participants: [currentUserId, otherUserId],
        participantDetails: {
          currentUserId: {
            'name': currentUserName,
            'photoUrl': currentUserPhoto,
          },
          otherUserId: {
            'name': otherUserName,
            'photoUrl': otherUserPhoto,
          },
        },
        unreadCount: {currentUserId: 0, otherUserId: 0},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await newChatRef.set(newChat.toJson());
      return newChat;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> setTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      final chatRef = _firestore.collection(FirebaseConstants.chatsCollection).doc(chatId);
      if (isTyping) {
        await chatRef.update({
          'typingUsers': FieldValue.arrayUnion([userId]),
        });
      } else {
        await chatRef.update({
          'typingUsers': FieldValue.arrayRemove([userId]),
        });
      }
    } catch (_) {}
  }

  @override
  Future<ChatModel> createGroupChat({
    required String name,
    required String currentUserId,
    required List<String> participantIds,
    String? photoUrl,
    String? description,
  }) async {
    try {
      final allParticipants = <String>{currentUserId, ...participantIds}.toList();
      final participantDetails = <String, dynamic>{};

      // Fetch user details for all participants
      for (var uid in allParticipants) {
        final userDoc = await _firestore.collection(FirebaseConstants.usersCollection).doc(uid).get();
        final userData = userDoc.data();
        participantDetails[uid] = {
          'name': userData?['displayName'] ?? 'User',
          'photoUrl': userData?['photoUrl'],
        };
      }

      final newChatRef = _firestore.collection(FirebaseConstants.chatsCollection).doc();
      final initialUnread = {for (var uid in allParticipants) uid: 0};

      final newGroup = ChatModel(
        chatId: newChatRef.id,
        type: 'group',
        participants: allParticipants,
        participantDetails: participantDetails,
        groupInfo: {
          'name': name,
          'description': description ?? '',
          'photoUrl': photoUrl,
          'admins': [currentUserId],
          'createdBy': currentUserId,
        },
        unreadCount: initialUnread,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await newChatRef.set(newGroup.toJson());
      return newGroup;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadChatMedia({
    required String chatId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final ext = fileName.contains('.') ? fileName.split('.').last : 'dat';
      final storageFileName = '${const Uuid().v4()}.$ext';
      final ref = _storage.ref().child('chats/$chatId/$storageFileName');

      final uploadTask = await ref.putFile(File(filePath));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw ServerException('Failed to upload media: $e');
    }
  }

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String currentUserId,
    required bool forEveryone,
  }) async {
    try {
      final msgRef = _firestore
          .collection(FirebaseConstants.chatsCollection)
          .doc(chatId)
          .collection(FirebaseConstants.messagesSubcollection)
          .doc(messageId);

      if (forEveryone) {
        await msgRef.update({
          'isDeleted': true,
          'content': 'This message was deleted',
          'mediaInfo': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await msgRef.update({
          'deletedFor': FieldValue.arrayUnion([currentUserId]),
        });
      }
    } catch (e) {
      throw ServerException('Failed to delete message: $e');
    }
  }
}
