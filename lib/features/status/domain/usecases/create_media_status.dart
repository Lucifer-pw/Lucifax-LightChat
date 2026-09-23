import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/status_repository.dart';

class CreateMediaStatus {
  final StatusRepository repository;

  CreateMediaStatus(this.repository);

  Future<Either<Failure, void>> call({
    required File file,
    required String type,
    String? caption,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) {
    return repository.createMediaStatus(
      file: file,
      type: type,
      caption: caption,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
    );
  }
}
