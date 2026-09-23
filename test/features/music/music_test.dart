import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucifax_lightchat/features/music/data/models/music_track_model.dart';
import 'package:lucifax_lightchat/features/music/presentation/bloc/music_player_state.dart';

void main() {
  group('Music Feature Tests', () {
    final now = DateTime.now();

    test('MusicTrackModel correctly parses from and to Map', () {
      final track = MusicTrackModel(
        id: 't123',
        title: 'LightChat Beats',
        artist: 'Lucifax Audio',
        album: 'Lo-Fi Chill',
        url: 'https://example.com/audio.mp3',
        coverUrl: 'https://example.com/cover.jpg',
        durationSeconds: 180,
        uploadedBy: 'user_admin',
        createdAt: now,
      );

      final map = track.toMap();
      expect(map['id'], 't123');
      expect(map['title'], 'LightChat Beats');
      expect(map['artist'], 'Lucifax Audio');
      expect(map['durationSeconds'], 180);
      expect(map['createdAt'], isA<Timestamp>());

      final parsed = MusicTrackModel.fromMap(map, 't123');
      expect(parsed.id, 't123');
      expect(parsed.title, 'LightChat Beats');
      expect(parsed.artist, 'Lucifax Audio');
      expect(parsed.album, 'Lo-Fi Chill');
    });

    test('MusicPlayerState copyWith and getters function correctly', () {
      const state = MusicPlayerState();
      expect(state.isPlaying, isFalse);
      expect(state.hasTrack, isFalse);

      final updatedState = state.copyWith(
        status: PlaybackStatus.playing,
        duration: const Duration(minutes: 3),
        position: const Duration(seconds: 45),
      );

      expect(updatedState.isPlaying, isTrue);
      expect(updatedState.position.inSeconds, 45);
      expect(updatedState.duration.inMinutes, 3);
    });
  });
}
