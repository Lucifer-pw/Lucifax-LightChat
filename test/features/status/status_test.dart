import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucifax_lightchat/features/status/data/models/status_item_model.dart';
import 'package:lucifax_lightchat/features/status/data/models/status_viewer_model.dart';
import 'package:lucifax_lightchat/features/status/data/models/user_status_group_model.dart';

void main() {
  group('Status Feature Tests', () {
    final now = DateTime.now();

    test('StatusItemModel correctly checks expiration (> 24 hours)', () {
      final activeItem = StatusItemModel(
        id: 's1',
        userId: 'u1',
        userName: 'Alice',
        type: 'text',
        content: 'Hello World Status!',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      );

      final expiredItem = StatusItemModel(
        id: 's2',
        userId: 'u1',
        userName: 'Alice',
        type: 'text',
        content: 'Old Status',
        createdAt: now.subtract(const Duration(hours: 25)),
        expiresAt: now.subtract(const Duration(hours: 1)),
      );

      expect(activeItem.isExpired, isFalse);
      expect(expiredItem.isExpired, isTrue);
    });

    test('StatusViewerModel correctly serializes and deserializes', () {
      final viewer = StatusViewerModel(
        userId: 'viewer1',
        userName: 'Bob',
        userPhotoUrl: 'https://example.com/photo.jpg',
        viewedAt: now,
      );

      final map = viewer.toMap();
      expect(map['userId'], 'viewer1');
      expect(map['userName'], 'Bob');
      expect(map['userPhotoUrl'], 'https://example.com/photo.jpg');
      expect(map['viewedAt'], isA<Timestamp>());

      final parsed = StatusViewerModel.fromMap(map);
      expect(parsed.userId, 'viewer1');
      expect(parsed.userName, 'Bob');
    });

    test('UserStatusGroup correctly calculates unviewed and active items', () {
      final item1 = StatusItemModel(
        id: 'item1',
        userId: 'u1',
        userName: 'Alice',
        type: 'text',
        content: 'First status',
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(hours: 22)),
        viewers: [
          StatusViewerModel(
            userId: 'my_user_id',
            userName: 'Me',
            viewedAt: now,
          ),
        ],
      );

      final item2 = StatusItemModel(
        id: 'item2',
        userId: 'u1',
        userName: 'Alice',
        type: 'image',
        content: 'https://example.com/status.jpg',
        caption: 'Sunset',
        createdAt: now.subtract(const Duration(minutes: 30)),
        expiresAt: now.add(const Duration(hours: 23, minutes: 30)),
        viewers: const [], // Not viewed by me
      );

      final group = UserStatusGroupModel(
        userId: 'u1',
        userName: 'Alice',
        items: [item1, item2],
        updatedAt: now,
      );

      expect(group.activeItems.length, 2);
      expect(group.hasUnviewed('my_user_id'), isTrue);
      expect(group.hasUnviewed('someone_else'), isTrue);
      expect(item1.isViewedBy('my_user_id'), isTrue);
      expect(item2.isViewedBy('my_user_id'), isFalse);
    });
  });
}
