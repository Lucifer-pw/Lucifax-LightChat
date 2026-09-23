import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/status_repository.dart';

class MarkStatusViewed {
  final StatusRepository repository;

  MarkStatusViewed(this.repository);

  Future<Either<Failure, void>> call({
    required String statusOwnerId,
    required String statusItemId,
    required String viewerId,
    required String viewerName,
    String? viewerPhotoUrl,
  }) {
    return repository.markStatusAsViewed(
      statusOwnerId: statusOwnerId,
      statusItemId: statusItemId,
      viewerId: viewerId,
      viewerName: viewerName,
      viewerPhotoUrl: viewerPhotoUrl,
    );
  }
}
