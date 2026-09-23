import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/status_repository.dart';

class CreateTextStatus {
  final StatusRepository repository;

  CreateTextStatus(this.repository);

  Future<Either<Failure, void>> call({
    required String text,
    required int backgroundColor,
    String? fontFamily,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) {
    return repository.createTextStatus(
      text: text,
      backgroundColor: backgroundColor,
      fontFamily: fontFamily,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
    );
  }
}
