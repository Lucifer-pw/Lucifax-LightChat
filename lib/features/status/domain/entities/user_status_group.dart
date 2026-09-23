import 'package:equatable/equatable.dart';
import 'status_item.dart';

class UserStatusGroup extends Equatable {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final List<StatusItem> items;
  final DateTime updatedAt;

  const UserStatusGroup({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.items,
    required this.updatedAt,
  });

  bool hasUnviewed(String currentUserId) {
    return items.any((item) => !item.isExpired && !item.isViewedBy(currentUserId));
  }

  List<StatusItem> get activeItems =>
      items.where((item) => !item.isExpired).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  StatusItem? get latestItem => activeItems.isNotEmpty ? activeItems.last : null;

  @override
  List<Object?> get props => [userId, userName, userPhotoUrl, items, updatedAt];
}
