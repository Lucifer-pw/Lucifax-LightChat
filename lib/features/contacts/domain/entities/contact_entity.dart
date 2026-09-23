import 'package:equatable/equatable.dart';

class ContactEntity extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String? registeredUid;
  final String? photoUrl;
  final String? bio;
  final bool isRegistered;

  const ContactEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.registeredUid,
    this.photoUrl,
    this.bio,
    this.isRegistered = false,
  });

  @override
  List<Object?> get props => [id, name, phoneNumber, registeredUid, photoUrl, bio, isRegistered];
}
