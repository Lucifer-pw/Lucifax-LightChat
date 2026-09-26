import 'package:equatable/equatable.dart';
import '../../data/services/audio_route_service.dart';
import '../../domain/entities/call_entity.dart';

enum CallStatus {
  initial,
  connecting,
  calling,
  ringing,
  connected,
  ended,
  error,
}

class CallState extends Equatable {
  final CallStatus status;
  final CallEntity? call;
  final bool isCaller;
  final bool isMuted;
  final bool isVideoOff;
  final bool isFrontCamera;
  final bool isSpeakerOn;
  final AudioOutputRoute audioRoute;
  final List<AudioOutputRoute> availableAudioRoutes;
  final bool isScreenSharing;
  final int duration;
  final String? errorMessage;
  final bool isRemoteVideoActive;

  const CallState({
    this.status = CallStatus.initial,
    this.call,
    this.isCaller = false,
    this.isMuted = false,
    this.isVideoOff = false,
    this.isFrontCamera = true,
    this.isSpeakerOn = false,
    this.audioRoute = AudioOutputRoute.earpiece,
    this.availableAudioRoutes = const [AudioOutputRoute.speaker, AudioOutputRoute.earpiece],
    this.isScreenSharing = false,
    this.duration = 0,
    this.errorMessage,
    this.isRemoteVideoActive = false,
  });

  CallState copyWith({
    CallStatus? status,
    CallEntity? call,
    bool? isCaller,
    bool? isMuted,
    bool? isVideoOff,
    bool? isFrontCamera,
    bool? isSpeakerOn,
    AudioOutputRoute? audioRoute,
    List<AudioOutputRoute>? availableAudioRoutes,
    bool? isScreenSharing,
    int? duration,
    String? errorMessage,
    bool? isRemoteVideoActive,
  }) {
    return CallState(
      status: status ?? this.status,
      call: call ?? this.call,
      isCaller: isCaller ?? this.isCaller,
      isMuted: isMuted ?? this.isMuted,
      isVideoOff: isVideoOff ?? this.isVideoOff,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isSpeakerOn: isSpeakerOn ?? (audioRoute != null ? audioRoute == AudioOutputRoute.speaker : this.isSpeakerOn),
      audioRoute: audioRoute ?? this.audioRoute,
      availableAudioRoutes: availableAudioRoutes ?? this.availableAudioRoutes,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
      isRemoteVideoActive: isRemoteVideoActive ?? this.isRemoteVideoActive,
    );
  }

  @override
  List<Object?> get props => [
        status,
        call,
        isCaller,
        isMuted,
        isVideoOff,
        isFrontCamera,
        isSpeakerOn,
        audioRoute,
        availableAudioRoutes,
        isScreenSharing,
        duration,
        errorMessage,
        isRemoteVideoActive,
      ];
}

