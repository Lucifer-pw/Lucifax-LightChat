import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/contact_entity.dart';
import '../repositories/contacts_repository.dart';

class FindUserByPhone {
  final ContactsRepository repository;

  FindUserByPhone(this.repository);

  Future<Either<Failure, ContactEntity?>> call(String phoneNumber) {
    return repository.findUserByPhoneNumber(phoneNumber);
  }
}
