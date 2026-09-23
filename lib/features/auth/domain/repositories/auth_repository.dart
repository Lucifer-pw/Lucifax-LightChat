import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, String>> sendPhoneOtp(String phoneNumber);
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String verificationId,
    required String smsCode,
  });
  Future<Either<Failure, UserEntity>> saveUserProfile({
    required String displayName,
    required String bio,
    File? imageFile,
  });
  Future<Either<Failure, void>> updateOnlineStatus(bool isOnline);
  Future<Either<Failure, void>> signOut();
}
