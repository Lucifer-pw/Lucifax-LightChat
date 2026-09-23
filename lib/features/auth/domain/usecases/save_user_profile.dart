import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SaveUserProfile {
  final AuthRepository repository;
  SaveUserProfile(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String displayName,
    required String bio,
    File? imageFile,
  }) {
    return repository.saveUserProfile(
      displayName: displayName,
      bio: bio,
      imageFile: imageFile,
    );
  }
}
