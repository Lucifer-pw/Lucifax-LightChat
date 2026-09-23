import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_status_group.dart';
import '../../domain/repositories/status_repository.dart';
import '../datasources/status_remote_datasource.dart';

class StatusRepositoryImpl implements StatusRepository {
  final StatusRemoteDataSource remoteDataSource;

  StatusRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<UserStatusGroup>> getRecentStatuses(String currentUserId) {
    return remoteDataSource.getRecentStatuses(currentUserId);
  }

  @override
  Stream<UserStatusGroup?> getMyStatus(String currentUserId) {
    return remoteDataSource.getMyStatus(currentUserId);
  }

  @override
  Future<Either<Failure, void>> createTextStatus({
    required String text,
    required int backgroundColor,
    String? fontFamily,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) async {
    try {
      await remoteDataSource.createTextStatus(
        text: text,
        backgroundColor: backgroundColor,
        fontFamily: fontFamily,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createMediaStatus({
    required File file,
    required String type,
    String? caption,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) async {
    try {
      await remoteDataSource.createMediaStatus(
        file: file,
        type: type,
        caption: caption,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markStatusAsViewed({
    required String statusOwnerId,
    required String statusItemId,
    required String viewerId,
    required String viewerName,
    String? viewerPhotoUrl,
  }) async {
    try {
      await remoteDataSource.markStatusAsViewed(
        statusOwnerId: statusOwnerId,
        statusItemId: statusItemId,
        viewerId: viewerId,
        viewerName: viewerName,
        viewerPhotoUrl: viewerPhotoUrl,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStatusItem({
    required String statusOwnerId,
    required String statusItemId,
  }) async {
    try {
      await remoteDataSource.deleteStatusItem(
        statusOwnerId: statusOwnerId,
        statusItemId: statusItemId,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
