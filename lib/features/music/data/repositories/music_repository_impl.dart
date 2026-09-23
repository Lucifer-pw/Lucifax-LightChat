import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/music_track.dart';
import '../../domain/repositories/music_repository.dart';
import '../datasources/music_remote_datasource.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicRemoteDataSource remoteDataSource;

  MusicRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<MusicTrack>> getMusicTracks() {
    return remoteDataSource.getMusicTracks();
  }

  @override
  Future<Either<Failure, void>> uploadMusicTrack({
    required File audioFile,
    required String title,
    required String artist,
    String? album,
    File? coverFile,
    required String uploadedBy,
  }) async {
    try {
      await remoteDataSource.uploadMusicTrack(
        audioFile: audioFile,
        title: title,
        artist: artist,
        album: album,
        coverFile: coverFile,
        uploadedBy: uploadedBy,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMusicTrack(String trackId) async {
    try {
      await remoteDataSource.deleteMusicTrack(trackId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
