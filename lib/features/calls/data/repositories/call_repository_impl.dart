import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/call_entity.dart';
import '../../domain/repositories/call_repository.dart';
import '../datasources/call_remote_datasource.dart';

class CallRepositoryImpl implements CallRepository {
  final CallRemoteDataSource remoteDataSource;

  CallRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, String>> makeCall(CallEntity call, Map<String, dynamic> offer) async {
    try {
      final callId = await remoteDataSource.makeCall(call, offer);
      return Right(callId);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> answerCall(String callId, Map<String, dynamic> answer) async {
    try {
      await remoteDataSource.answerCall(callId, answer);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCallStatus(String callId, String status, {int? duration}) async {
    try {
      await remoteDataSource.updateCallStatus(callId, status, duration: duration);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCandidate(
    String callId,
    String candidateType,
    Map<String, dynamic> candidate,
  ) async {
    try {
      await remoteDataSource.addCandidate(callId, candidateType, candidate);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<CallEntity?> getCallStream(String callId) {
    return remoteDataSource.getCallStream(callId);
  }

  @override
  Stream<List<Map<String, dynamic>>> getCandidatesStream(String callId, String candidateType) {
    return remoteDataSource.getCandidatesStream(callId, candidateType);
  }

  @override
  Stream<List<CallEntity>> getIncomingCallsStream(String currentUserId) {
    return remoteDataSource.getIncomingCallsStream(currentUserId);
  }

  @override
  Stream<List<CallEntity>> getCallHistoryStream(String currentUserId) {
    return remoteDataSource.getCallHistoryStream(currentUserId);
  }
}
