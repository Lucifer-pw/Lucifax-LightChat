import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/call_entity.dart';

abstract class CallRepository {
  Future<Either<Failure, String>> makeCall(CallEntity call, Map<String, dynamic> offer);
  Future<Either<Failure, void>> answerCall(String callId, Map<String, dynamic> answer);
  Future<Either<Failure, void>> updateCallStatus(String callId, String status, {int? duration});
  Future<Either<Failure, void>> addCandidate(String callId, String candidateType, Map<String, dynamic> candidate);
  Stream<CallEntity?> getCallStream(String callId);
  Stream<List<Map<String, dynamic>>> getCandidatesStream(String callId, String candidateType);
  Stream<List<CallEntity>> getIncomingCallsStream(String currentUserId);
  Stream<List<CallEntity>> getCallHistoryStream(String currentUserId);
}
