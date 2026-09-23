import '../entities/music_track.dart';
import '../repositories/music_repository.dart';

class GetMusicTracks {
  final MusicRepository repository;

  GetMusicTracks(this.repository);

  Stream<List<MusicTrack>> call() {
    return repository.getMusicTracks();
  }
}
