import 'package:equatable/equatable.dart';

class MusicTrack extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String url;
  final String? coverUrl;
  final int durationSeconds;
  final String uploadedBy;
  final DateTime createdAt;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.url,
    this.coverUrl,
    required this.durationSeconds,
    required this.uploadedBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        url,
        coverUrl,
        durationSeconds,
        uploadedBy,
        createdAt,
      ];
}
