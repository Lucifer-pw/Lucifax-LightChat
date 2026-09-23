import 'package:equatable/equatable.dart';
import 'status_viewer.dart';

class StatusItem extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String type; // 'text', 'image', 'video'
  final String content; // Text string or Storage URL
  final String? caption;
  final int? backgroundColor; // ARGB int for text story
  final String? fontFamily;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<StatusViewer> viewers;

  const StatusItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.type,
    required this.content,
    this.caption,
    this.backgroundColor,
    this.fontFamily,
    required this.createdAt,
    required this.expiresAt,
    this.viewers = const [],
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool isViewedBy(String currentUserId) {
    return viewers.any((v) => v.userId == currentUserId);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userPhotoUrl,
        type,
        content,
        caption,
        backgroundColor,
        fontFamily,
        createdAt,
        expiresAt,
        viewers,
      ];
}
