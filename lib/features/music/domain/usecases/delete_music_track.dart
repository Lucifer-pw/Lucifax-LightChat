import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/music_repository.dart';

class DeleteMusicTrack {
  final MusicRepository repository;

  DeleteMusicTrack(this.repository);

  Future<Either<Failure, void>> call(String trackId) {
    return repository.deleteMusicTrack(trackId);
  }
}
