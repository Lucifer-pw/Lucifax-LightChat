import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/status_item.dart';
import 'status_viewer_model.dart';

class StatusItemModel extends StatusItem {
  const StatusItemModel({
    required super.id,
    required super.userId,
    required super.userName,
    super.userPhotoUrl,
    required super.type,
    required super.content,
    super.caption,
    super.backgroundColor,
    super.fontFamily,
    required super.createdAt,
    required super.expiresAt,
    super.viewers,
  });

  factory StatusItemModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime createdAt = DateTime.now();
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      createdAt = DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    }

    DateTime expiresAt = createdAt.add(const Duration(hours: 24));
    if (map['expiresAt'] is Timestamp) {
      expiresAt = (map['expiresAt'] as Timestamp).toDate();
    } else if (map['expiresAt'] is String) {
      expiresAt = DateTime.tryParse(map['expiresAt'] as String) ?? expiresAt;
    }

    final viewersRaw = map['viewers'] as List<dynamic>? ?? [];
    final viewers = viewersRaw
        .map((v) => StatusViewerModel.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();

    return StatusItemModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      type: map['type'] ?? 'text',
      content: map['content'] ?? '',
      caption: map['caption'],
      backgroundColor: map['backgroundColor'] as int?,
      fontFamily: map['fontFamily'] as String?,
      createdAt: createdAt,
      expiresAt: expiresAt,
      viewers: viewers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'type': type,
      'content': content,
      'caption': caption,
      'backgroundColor': backgroundColor,
      'fontFamily': fontFamily,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewers': viewers.map((v) {
        if (v is StatusViewerModel) {
          return v.toMap();
        }
        return {
          'userId': v.userId,
          'userName': v.userName,
          'userPhotoUrl': v.userPhotoUrl,
          'viewedAt': Timestamp.fromDate(v.viewedAt),
        };
      }).toList(),
    };
  }
}
