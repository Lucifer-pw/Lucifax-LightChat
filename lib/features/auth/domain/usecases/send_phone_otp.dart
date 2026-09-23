import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SendPhoneOtp {
  final AuthRepository repository;
  SendPhoneOtp(this.repository);

  Future<Either<Failure, String>> call(String phoneNumber) {
    return repository.sendPhoneOtp(phoneNumber);
  }
}
