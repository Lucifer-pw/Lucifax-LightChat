import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.displayName,
    required super.phoneNumber,
    super.email,
    super.photoUrl,
    super.coverPhotoUrl,
    super.bio,
    super.isOnline,
    super.lastSeen,
    super.createdAt,
    super.updatedAt,
    super.theme,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserModel(
      uid: uid,
      displayName: json['displayName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      photoUrl: json['photoUrl'],
      coverPhotoUrl: json['coverPhotoUrl'],
      bio: json['bio'] ?? "Hey! I'm using LightChat",
      isOnline: json['isOnline'] ?? false,
      lastSeen: parseDate(json['lastSeen']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      theme: json['theme'] != null ? Map<String, dynamic>.from(json['theme']) : null,
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data, doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'email': email,
      'photoUrl': photoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'bio': bio,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'theme': theme,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? phoneNumber,
    String? email,
    String? photoUrl,
    String? coverPhotoUrl,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
    Map<String, dynamic>? theme,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      theme: theme ?? this.theme,
    );
  }
}
