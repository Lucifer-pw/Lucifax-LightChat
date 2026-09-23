import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/status_viewer.dart';

class StatusViewerModel extends StatusViewer {
  const StatusViewerModel({
    required super.userId,
    required super.userName,
    super.userPhotoUrl,
    required super.viewedAt,
  });

  factory StatusViewerModel.fromMap(Map<String, dynamic> map) {
    DateTime viewedAt = DateTime.now();
    if (map['viewedAt'] is Timestamp) {
      viewedAt = (map['viewedAt'] as Timestamp).toDate();
    } else if (map['viewedAt'] is String) {
      viewedAt = DateTime.tryParse(map['viewedAt'] as String) ?? DateTime.now();
    }

    return StatusViewerModel(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      viewedAt: viewedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'viewedAt': Timestamp.fromDate(viewedAt),
    };
  }
}
