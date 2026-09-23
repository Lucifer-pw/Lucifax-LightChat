import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/status_repository.dart';

class DeleteStatusItem {
  final StatusRepository repository;

  DeleteStatusItem(this.repository);

  Future<Either<Failure, void>> call({
    required String statusOwnerId,
    required String statusItemId,
  }) {
    return repository.deleteStatusItem(
      statusOwnerId: statusOwnerId,
      statusItemId: statusItemId,
    );
  }
}
