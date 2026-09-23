import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String displayName;
  final String phoneNumber;
  final String? email;
  final String? photoUrl;
  final String? coverPhotoUrl;
  final String bio;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? theme;

  const UserEntity({
    required this.uid,
    required this.displayName,
    required this.phoneNumber,
    this.email,
    this.photoUrl,
    this.coverPhotoUrl,
    this.bio = "Hey! I'm using LightChat",
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
    this.theme,
  });

  @override
  List<Object?> get props => [
        uid,
        displayName,
        phoneNumber,
        email,
        photoUrl,
        coverPhotoUrl,
        bio,
        isOnline,
        lastSeen,
        createdAt,
        updatedAt,
        theme,
      ];
}
