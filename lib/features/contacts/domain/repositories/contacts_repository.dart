import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/contact_entity.dart';

abstract class ContactsRepository {
  Future<Either<Failure, List<ContactEntity>>> syncAndGetContacts();
  Future<Either<Failure, ContactEntity?>> findUserByPhoneNumber(String phoneNumber);
}
