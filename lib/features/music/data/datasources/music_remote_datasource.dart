import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/music_track_model.dart';

abstract class MusicRemoteDataSource {
  Stream<List<MusicTrackModel>> getMusicTracks();
  Future<void> uploadMusicTrack({
    required File audioFile,
    required String title,
    required String artist,
    String? album,
    File? coverFile,
    required String uploadedBy,
  });
  Future<void> deleteMusicTrack(String trackId);
}

class MusicRemoteDataSourceImpl implements MusicRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final Uuid uuid;

  MusicRemoteDataSourceImpl({
    required this.firestore,
    required this.storage,
    this.uuid = const Uuid(),
  });

  @override
  Stream<List<MusicTrackModel>> getMusicTracks() {
    return firestore
        .collection(FirebaseConstants.musicCollection)
        .snapshots()
        .map((snapshot) {
      final tracks = snapshot.docs
          .map((doc) => MusicTrackModel.fromMap(doc.data(), doc.id))
          .toList();
      tracks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tracks;
    });
  }

  @override
  Future<void> uploadMusicTrack({
    required File audioFile,
    required String title,
    required String artist,
    String? album,
    File? coverFile,
    required String uploadedBy,
  }) async {
    try {
      final trackId = uuid.v4();

      // 1. Upload audio file
      final audioStorageRef = storage
          .ref()
          .child(FirebaseConstants.musicFilesPath)
          .child('$trackId.mp3');
      final audioUploadTask = await audioStorageRef.putFile(
        audioFile,
        SettableMetadata(contentType: 'audio/mpeg'),
      );
      final audioUrl = await audioUploadTask.ref.getDownloadURL();

      // 2. Upload cover if available
      String? coverUrl;
      if (coverFile != null) {
        final coverStorageRef = storage
            .ref()
            .child(FirebaseConstants.coverPhotosPath)
            .child('$trackId.jpg');
        final coverUploadTask = await coverStorageRef.putFile(
          coverFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        coverUrl = await coverUploadTask.ref.getDownloadURL();
      }

      final now = DateTime.now();
      final trackModel = MusicTrackModel(
        id: trackId,
        title: title,
        artist: artist,
        album: album,
        url: audioUrl,
        coverUrl: coverUrl,
        durationSeconds: 0,
        uploadedBy: uploadedBy,
        createdAt: now,
      );

      await firestore
          .collection(FirebaseConstants.musicCollection)
          .doc(trackId)
          .set(trackModel.toMap());
    } catch (e) {
      throw ServerException('Failed to upload music track: $e');
    }
  }

  @override
  Future<void> deleteMusicTrack(String trackId) async {
    try {
      await firestore
          .collection(FirebaseConstants.musicCollection)
          .doc(trackId)
          .delete();
    } catch (e) {
      throw ServerException('Failed to delete music track: $e');
    }
  }
}
