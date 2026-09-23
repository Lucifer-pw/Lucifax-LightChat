import 'package:equatable/equatable.dart';
import '../../domain/entities/music_track.dart';

enum PlaybackStatus { initial, loading, playing, paused, stopped, error }

class MusicPlayerState extends Equatable {
  final PlaybackStatus status;
  final MusicTrack? currentTrack;
  final Duration position;
  final Duration duration;
  final String? errorMessage;
  final bool isLooping;

  const MusicPlayerState({
    this.status = PlaybackStatus.initial,
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
    this.isLooping = false,
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get hasTrack => currentTrack != null;

  MusicPlayerState copyWith({
    PlaybackStatus? status,
    MusicTrack? currentTrack,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    bool? isLooping,
  }) {
    return MusicPlayerState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
      isLooping: isLooping ?? this.isLooping,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentTrack,
        position,
        duration,
        errorMessage,
        isLooping,
      ];
}
