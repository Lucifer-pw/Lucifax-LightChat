import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/call_repository.dart';

class EndCall {
  final CallRepository repository;

  EndCall(this.repository);

  Future<Either<Failure, void>> call(String callId, {String status = 'ended', int? duration}) {
    return repository.updateCallStatus(callId, status, duration: duration);
  }
}
