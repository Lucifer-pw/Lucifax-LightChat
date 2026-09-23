import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/contact_entity.dart';
import '../repositories/contacts_repository.dart';

class SyncContacts {
  final ContactsRepository repository;
  SyncContacts(this.repository);

  Future<Either<Failure, List<ContactEntity>>> call() {
    return repository.syncAndGetContacts();
  }
}
