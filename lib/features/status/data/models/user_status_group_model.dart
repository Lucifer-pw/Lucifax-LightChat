import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_status_group.dart';
import 'status_item_model.dart';

class UserStatusGroupModel extends UserStatusGroup {
  const UserStatusGroupModel({
    required super.userId,
    required super.userName,
    super.userPhotoUrl,
    required super.items,
    required super.updatedAt,
  });

  factory UserStatusGroupModel.fromMap(Map<String, dynamic> map, String userId, List<StatusItemModel> items) {
    DateTime updatedAt = DateTime.now();
    if (map['updatedAt'] is Timestamp) {
      updatedAt = (map['updatedAt'] as Timestamp).toDate();
    } else if (map['updatedAt'] is String) {
      updatedAt = DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now();
    }

    return UserStatusGroupModel(
      userId: userId,
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      items: items,
      updatedAt: updatedAt,
    );
  }
}
