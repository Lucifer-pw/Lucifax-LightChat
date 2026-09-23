import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/music_track.dart';

class MusicTrackModel extends MusicTrack {
  const MusicTrackModel({
    required super.id,
    required super.title,
    required super.artist,
    super.album,
    required super.url,
    super.coverUrl,
    required super.durationSeconds,
    required super.uploadedBy,
    required super.createdAt,
  });

  factory MusicTrackModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime createdAt = DateTime.now();
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      createdAt = DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    }

    return MusicTrackModel(
      id: id,
      title: map['title'] ?? 'Unknown Track',
      artist: map['artist'] ?? 'Unknown Artist',
      album: map['album'],
      url: map['url'] ?? '',
      coverUrl: map['coverUrl'],
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      uploadedBy: map['uploadedBy'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'url': url,
      'coverUrl': coverUrl,
      'durationSeconds': durationSeconds,
      'uploadedBy': uploadedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
