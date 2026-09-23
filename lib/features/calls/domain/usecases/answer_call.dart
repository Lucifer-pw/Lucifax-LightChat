import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/call_repository.dart';

class AnswerCall {
  final CallRepository repository;

  AnswerCall(this.repository);

  Future<Either<Failure, void>> call(String callId, Map<String, dynamic> answer) {
    return repository.answerCall(callId, answer);
  }
}
