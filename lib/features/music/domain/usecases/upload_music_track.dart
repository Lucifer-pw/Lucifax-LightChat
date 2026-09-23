import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/music_repository.dart';

class UploadMusicTrack {
  final MusicRepository repository;

  UploadMusicTrack(this.repository);

  Future<Either<Failure, void>> call({
    required File audioFile,
    required String title,
    required String artist,
    String? album,
    File? coverFile,
    required String uploadedBy,
  }) {
    return repository.uploadMusicTrack(
      audioFile: audioFile,
      title: title,
      artist: artist,
      album: album,
      coverFile: coverFile,
      uploadedBy: uploadedBy,
    );
  }
}
