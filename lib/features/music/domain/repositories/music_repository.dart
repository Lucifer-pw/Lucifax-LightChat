import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/music_track.dart';

abstract class MusicRepository {
  Stream<List<MusicTrack>> getMusicTracks();
  Future<Either<Failure, void>> uploadMusicTrack({
    required File audioFile,
    required String title,
    required String artist,
    String? album,
    File? coverFile,
    required String uploadedBy,
  });
  Future<Either<Failure, void>> deleteMusicTrack(String trackId);
}
