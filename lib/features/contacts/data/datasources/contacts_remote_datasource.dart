import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/phone_number_formatter.dart';
import '../../domain/entities/contact_entity.dart';

abstract class ContactsRemoteDataSource {
  Future<List<ContactEntity>> getDeviceContactsAndMatch();
}

class ContactsRemoteDataSourceImpl implements ContactsRemoteDataSource {
  final FirebaseFirestore _firestore;

  ContactsRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ContactEntity>> getDeviceContactsAndMatch() async {
    try {
      final permission = await FlutterContacts.requestPermission(readonly: true);
      if (!permission) {
        throw const PermissionException('Contacts permission denied');
      }

      final deviceContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final normalizedMap = <String, String>{}; // phone -> name
      for (var contact in deviceContacts) {
        for (var phone in contact.phones) {
          final normalized = PhoneNumberFormatter.toE164(phone.number);
          if (PhoneNumberFormatter.isValid(normalized)) {
            normalizedMap[normalized] = contact.displayName;
          }
        }
      }

      if (normalizedMap.isEmpty) return [];

      final allPhones = normalizedMap.keys.toList();
      final matchedContacts = <ContactEntity>[];

      // Query registered users in chunks of 30 (Firestore whereIn limit)
      for (var i = 0; i < allPhones.length; i += 30) {
        final chunk = allPhones.sublist(
          i,
          i + 30 > allPhones.length ? allPhones.length : i + 30,
        );

        final query = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .where('phoneNumber', whereIn: chunk)
            .get();

        for (var doc in query.docs) {
          final data = doc.data();
          final phone = data['phoneNumber'] ?? '';
          matchedContacts.add(
            ContactEntity(
              id: doc.id,
              name: normalizedMap[phone] ?? data['displayName'] ?? phone,
              phoneNumber: phone,
              registeredUid: doc.id,
              photoUrl: data['photoUrl'],
              bio: data['bio'],
              isRegistered: true,
            ),
          );
        }
      }

      return matchedContacts;
    } catch (e) {
      if (e is PermissionException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
