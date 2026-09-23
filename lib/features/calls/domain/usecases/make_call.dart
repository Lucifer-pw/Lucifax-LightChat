import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/call_entity.dart';
import '../repositories/call_repository.dart';

class MakeCall {
  final CallRepository repository;

  MakeCall(this.repository);

  Future<Either<Failure, String>> call(CallEntity callEntity, Map<String, dynamic> offer) {
    return repository.makeCall(callEntity, offer);
  }
}
