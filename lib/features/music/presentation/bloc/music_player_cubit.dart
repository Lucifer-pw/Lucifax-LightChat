import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/music_track.dart';
import 'music_player_state.dart';

class MusicPlayerCubit extends Cubit<MusicPlayerState> {
  final AudioPlayer _audioPlayer;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  MusicPlayerCubit({AudioPlayer? audioPlayer})
      : _audioPlayer = audioPlayer ?? AudioPlayer(),
        super(const MusicPlayerState()) {
    _initListeners();
  }

  void _initListeners() {
    _posSub = _audioPlayer.onPositionChanged.listen((pos) {
      emit(state.copyWith(position: pos));
    });

    _durSub = _audioPlayer.onDurationChanged.listen((dur) {
      emit(state.copyWith(duration: dur));
    });

    _stateSub = _audioPlayer.onPlayerStateChanged.listen((playerState) {
      if (playerState == PlayerState.playing) {
        emit(state.copyWith(status: PlaybackStatus.playing));
      } else if (playerState == PlayerState.paused) {
        emit(state.copyWith(status: PlaybackStatus.paused));
      } else if (playerState == PlayerState.completed) {
        emit(state.copyWith(status: PlaybackStatus.stopped, position: Duration.zero));
      }
    });
  }

  Future<void> playTrack(MusicTrack track) async {
    try {
      emit(state.copyWith(
        status: PlaybackStatus.loading,
        currentTrack: track,
        position: Duration.zero,
      ));

      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(track.url);
      await _audioPlayer.resume();
    } catch (e) {
      emit(state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to play track: $e',
      ));
    }
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _audioPlayer.pause();
    } else if (state.hasTrack) {
      await _audioPlayer.resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    emit(const MusicPlayerState());
  }

  Future<void> toggleLoop() async {
    final nextLoop = !state.isLooping;
    await _audioPlayer.setReleaseMode(
      nextLoop ? ReleaseMode.loop : ReleaseMode.release,
    );
    emit(state.copyWith(isLooping: nextLoop));
  }

  @override
  Future<void> close() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}
