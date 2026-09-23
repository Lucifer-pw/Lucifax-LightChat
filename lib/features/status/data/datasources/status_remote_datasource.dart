import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/status_item_model.dart';
import '../models/status_viewer_model.dart';
import '../models/user_status_group_model.dart';

abstract class StatusRemoteDataSource {
  Stream<List<UserStatusGroupModel>> getRecentStatuses(String currentUserId);
  Stream<UserStatusGroupModel?> getMyStatus(String currentUserId);

  Future<void> createTextStatus({
    required String text,
    required int backgroundColor,
    String? fontFamily,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  });

  Future<void> createMediaStatus({
    required File file,
    required String type,
    String? caption,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  });

  Future<void> markStatusAsViewed({
    required String statusOwnerId,
    required String statusItemId,
    required String viewerId,
    required String viewerName,
    String? viewerPhotoUrl,
  });

  Future<void> deleteStatusItem({
    required String statusOwnerId,
    required String statusItemId,
  });
}

class StatusRemoteDataSourceImpl implements StatusRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final Uuid uuid;

  StatusRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
    this.uuid = const Uuid(),
  });

  @override
  Stream<List<UserStatusGroupModel>> getRecentStatuses(String currentUserId) {
    return firestore
        .collection(FirebaseConstants.statusesCollection)
        .snapshots()
        .map((snapshot) {
      final groups = <UserStatusGroupModel>[];

      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId) continue; // Skip own status

        final data = doc.data();
        final rawItems = data['items'] as List<dynamic>? ?? [];

        final items = <StatusItemModel>[];
        for (var itemMap in rawItems) {
          try {
            final model = StatusItemModel.fromMap(
              Map<String, dynamic>.from(itemMap as Map),
              itemMap['id'] ?? '',
            );
            if (!model.isExpired) {
              items.add(model);
            }
          } catch (_) {}
        }

        if (items.isNotEmpty) {
          items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          groups.add(UserStatusGroupModel.fromMap(data, doc.id, items));
        }
      }

      // Sort by latest update time
      groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return groups;
    });
  }

  @override
  Stream<UserStatusGroupModel?> getMyStatus(String currentUserId) {
    return firestore
        .collection(FirebaseConstants.statusesCollection)
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      final rawItems = data['items'] as List<dynamic>? ?? [];

      final items = <StatusItemModel>[];
      for (var itemMap in rawItems) {
        try {
          final model = StatusItemModel.fromMap(
            Map<String, dynamic>.from(itemMap as Map),
            itemMap['id'] ?? '',
          );
          if (!model.isExpired) {
            items.add(model);
          }
        } catch (_) {}
      }

      if (items.isEmpty) return null;

      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return UserStatusGroupModel.fromMap(data, doc.id, items);
    });
  }

  @override
  Future<void> createTextStatus({
    required String text,
    required int backgroundColor,
    String? fontFamily,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) async {
    try {
      final statusId = uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final statusItem = StatusItemModel(
        id: statusId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        type: 'text',
        content: text,
        backgroundColor: backgroundColor,
        fontFamily: fontFamily,
        createdAt: now,
        expiresAt: expiresAt,
        viewers: const [],
      );

      final docRef = firestore.collection(FirebaseConstants.statusesCollection).doc(userId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        await docRef.update({
          'userName': userName,
          'userPhotoUrl': userPhotoUrl,
          'updatedAt': Timestamp.fromDate(now),
          'items': FieldValue.arrayUnion([statusItem.toMap()]),
        });
      } else {
        await docRef.set({
          'userId': userId,
          'userName': userName,
          'userPhotoUrl': userPhotoUrl,
          'updatedAt': Timestamp.fromDate(now),
          'items': [statusItem.toMap()],
        });
      }
    } catch (e) {
      throw ServerException('Failed to create text status: $e');
    }
  }

  @override
  Future<void> createMediaStatus({
    required File file,
    required String type,
    String? caption,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) async {
    try {
      final statusId = uuid.v4();
      final fileExt = type == 'video' ? 'mp4' : 'jpg';
      final storageRef = storage
          .ref()
          .child(FirebaseConstants.statusMediaPath)
          .child(userId)
          .child('$statusId.$fileExt');

      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: type == 'video' ? 'video/mp4' : 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final statusItem = StatusItemModel(
        id: statusId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        type: type,
        content: downloadUrl,
        caption: caption,
        createdAt: now,
        expiresAt: expiresAt,
        viewers: const [],
      );

      final docRef = firestore.collection(FirebaseConstants.statusesCollection).doc(userId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        await docRef.update({
          'userName': userName,
          'userPhotoUrl': userPhotoUrl,
          'updatedAt': Timestamp.fromDate(now),
          'items': FieldValue.arrayUnion([statusItem.toMap()]),
        });
      } else {
        await docRef.set({
          'userId': userId,
          'userName': userName,
          'userPhotoUrl': userPhotoUrl,
          'updatedAt': Timestamp.fromDate(now),
          'items': [statusItem.toMap()],
        });
      }
    } catch (e) {
      throw ServerException('Failed to upload media status: $e');
    }
  }

  @override
  Future<void> markStatusAsViewed({
    required String statusOwnerId,
    required String statusItemId,
    required String viewerId,
    required String viewerName,
    String? viewerPhotoUrl,
  }) async {
    try {
      final docRef = firestore.collection(FirebaseConstants.statusesCollection).doc(statusOwnerId);
      final docSnap = await docRef.get();

      if (!docSnap.exists || docSnap.data() == null) return;

      final data = docSnap.data()!;
      final rawItems = List<Map<String, dynamic>>.from(data['items'] ?? []);

      bool modified = false;
      for (int i = 0; i < rawItems.length; i++) {
        if (rawItems[i]['id'] == statusItemId) {
          final viewers = List<Map<String, dynamic>>.from(rawItems[i]['viewers'] ?? []);
          final alreadyViewed = viewers.any((v) => v['userId'] == viewerId);

          if (!alreadyViewed) {
            viewers.add(StatusViewerModel(
              userId: viewerId,
              userName: viewerName,
              userPhotoUrl: viewerPhotoUrl,
              viewedAt: DateTime.now(),
            ).toMap());

            rawItems[i]['viewers'] = viewers;
            modified = true;
          }
          break;
        }
      }

      if (modified) {
        await docRef.update({'items': rawItems});
      }
    } catch (e) {
      throw ServerException('Failed to record status view: $e');
    }
  }

  @override
  Future<void> deleteStatusItem({
    required String statusOwnerId,
    required String statusItemId,
  }) async {
    try {
      final docRef = firestore.collection(FirebaseConstants.statusesCollection).doc(statusOwnerId);
      final docSnap = await docRef.get();

      if (!docSnap.exists || docSnap.data() == null) return;

      final data = docSnap.data()!;
      final rawItems = List<Map<String, dynamic>>.from(data['items'] ?? []);

      rawItems.removeWhere((item) => item['id'] == statusItemId);

      if (rawItems.isEmpty) {
        await docRef.delete();
      } else {
        await docRef.update({
          'items': rawItems,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw ServerException('Failed to delete status item: $e');
    }
  }
}
