import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<User?> get authStateChanges;
  User? get currentFirebaseUser;
  Future<UserModel?> getUserData(String uid);
  Future<String> sendPhoneOtp(String phoneNumber);
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<UserModel> saveUserProfile({
    required String displayName,
    required String bio,
    File? imageFile,
  });
  Future<void> updateOnlineStatus(bool isOnline);
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  @override
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) return null;
      return UserModel.fromDocument(doc);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> sendPhoneOtp(String phoneNumber) async {
    final completer = Completer<String>();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution on Android
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(
              AuthException(e.message ?? 'Verification failed', e.code),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );

      return await completer.future;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw const AuthException('Failed to sign in: user is null');
      }

      // Try fetching or creating Firestore user with fallback
      try {
        final existingDoc = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 4));

        if (existingDoc.exists) {
          return UserModel.fromDocument(existingDoc);
        } else {
          final newUser = UserModel(
            uid: user.uid,
            displayName: '',
            phoneNumber: user.phoneNumber ?? '',
            isOnline: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await _firestore
              .collection(FirebaseConstants.usersCollection)
              .doc(user.uid)
              .set(newUser.toJson())
              .timeout(const Duration(seconds: 4));

          return newUser;
        }
      } catch (firestoreError) {
        // Return in-memory user to allow user to proceed to ProfileSetupPage
        return UserModel(
          uid: user.uid,
          displayName: '',
          phoneNumber: user.phoneNumber ?? '',
          isOnline: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Invalid OTP code', e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> saveUserProfile({
    required String displayName,
    required String bio,
    File? imageFile,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException('Not authenticated');
      }

      String? photoUrl;

      if (imageFile != null && imageFile.existsSync()) {
        try {
          final ref = _storage
              .ref()
              .child(FirebaseConstants.profilePhotosPath)
              .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

          final metadata = SettableMetadata(contentType: 'image/jpeg');
          final uploadTask = await ref.putFile(imageFile, metadata);
          photoUrl = await uploadTask.ref.getDownloadURL();
        } catch (storageError) {
          // If Firebase Storage is unavailable (e.g. requires Blaze plan), fall back to Base64 in Firestore directly
          final bytes = await imageFile.readAsBytes();
          final base64String = base64Encode(bytes);
          photoUrl = 'data:image/jpeg;base64,$base64String';
        }
      }

      final updateData = <String, dynamic>{
        'uid': user.uid,
        'displayName': displayName,
        'phoneNumber': user.phoneNumber ?? '',
        'bio': bio,
        'isOnline': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
      }

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      // ── Sync participantDetails in all chats this user belongs to ──
      try {
        final chatQuery = await _firestore
            .collection(FirebaseConstants.chatsCollection)
            .where('participants', arrayContains: user.uid)
            .get();

        if (chatQuery.docs.isNotEmpty) {
          final batch = _firestore.batch();
          for (final doc in chatQuery.docs) {
            batch.update(doc.reference, {
              'participantDetails.${user.uid}.name': displayName,
              if (photoUrl != null) 'participantDetails.${user.uid}.photoUrl': photoUrl,
            });
          }
          await batch.commit();
        }
      } catch (_) {
        // Best-effort: don't fail profile save if chat sync fails
      }

      final updatedDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .get();

      return UserModel.fromDocument(updatedDoc);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid)
          .update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Best effort update
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await updateOnlineStatus(false);
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
