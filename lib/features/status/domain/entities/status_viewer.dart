import 'package:equatable/equatable.dart';

class StatusViewer extends Equatable {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DateTime viewedAt;

  const StatusViewer({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.viewedAt,
  });

  @override
  List<Object?> get props => [userId, userName, userPhotoUrl, viewedAt];
}
