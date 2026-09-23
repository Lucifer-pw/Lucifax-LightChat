import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/status_item.dart';
import '../entities/user_status_group.dart';

abstract class StatusRepository {
  Stream<List<UserStatusGroup>> getRecentStatuses(String currentUserId);
  Stream<UserStatusGroup?> getMyStatus(String currentUserId);

  Future<Either<Failure, void>> createTextStatus({
    required String text,
    required int backgroundColor,
    String? fontFamily,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  });

  Future<Either<Failure, void>> createMediaStatus({
    required File file,
    required String type,
    String? caption,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  });

  Future<Either<Failure, void>> markStatusAsViewed({
    required String statusOwnerId,
    required String statusItemId,
    required String viewerId,
    required String viewerName,
    String? viewerPhotoUrl,
  });

  Future<Either<Failure, void>> deleteStatusItem({
    required String statusOwnerId,
    required String statusItemId,
  });
}
