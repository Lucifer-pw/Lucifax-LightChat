import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  Function(RTCIceCandidate candidate)? onIceCandidate;
  Function(MediaStream stream)? onRemoteStream;
  Function(RTCPeerConnectionState state)? onConnectionState;

  bool _isInitialized = false;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
        ]
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Future<void> initializeRenderers() async {
    if (!_isInitialized) {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      _isInitialized = true;
    }
  }

  Future<MediaStream> openUserMedia({required bool isVideo}) async {
    await initializeRenderers();

    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': isVideo
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    if (isVideo) {
      localRenderer.srcObject = _localStream;
    }

    return _localStream!;
  }

  Future<void> createPeerConnectionInstance({required bool isVideo}) async {
    _peerConnection = await createPeerConnection(_iceServers, _config);

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        onIceCandidate?.call(candidate);
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        remoteRenderer.srcObject = _remoteStream;
        onRemoteStream?.call(_remoteStream!);
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      onConnectionState?.call(state);
    };
  }

  Future<Map<String, dynamic>> createOffer({required bool isVideo}) async {
    if (_peerConnection == null) {
      await createPeerConnectionInstance(isVideo: isVideo);
    }

    final offerConstraints = <String, dynamic>{
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': isVideo ? 1 : 0,
    };

    RTCSessionDescription offer = await _peerConnection!.createOffer(offerConstraints);
    await _peerConnection!.setLocalDescription(offer);

    return {
      'sdp': offer.sdp,
      'type': offer.type,
    };
  }

  Future<Map<String, dynamic>> createAnswer({required bool isVideo}) async {
    if (_peerConnection == null) {
      await createPeerConnectionInstance(isVideo: isVideo);
    }

    final answerConstraints = <String, dynamic>{
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': isVideo ? 1 : 0,
    };

    RTCSessionDescription answer = await _peerConnection!.createAnswer(answerConstraints);
    await _peerConnection!.setLocalDescription(answer);

    return {
      'sdp': answer.sdp,
      'type': answer.type,
    };
  }

  Future<void> setRemoteDescription(Map<String, dynamic> sdpMap) async {
    if (_peerConnection != null) {
      final desc = RTCSessionDescription(sdpMap['sdp'], sdpMap['type']);
      await _peerConnection!.setRemoteDescription(desc);
    }
  }

  Future<void> addCandidate(Map<String, dynamic> candidateMap) async {
    if (_peerConnection != null) {
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    }
  }

  void toggleMicrophone(bool isMuted) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
    }
  }

  void toggleVideo(bool isVideoOff) {
    if (_localStream != null) {
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = !isVideoOff;
      }
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks.first);
      }
    }
  }

  Future<void> setSpeakerphone(bool enable) async {
    await Helper.setSpeakerphoneOn(enable);
  }

  Future<void> dispose() async {
    try {
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          await track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }

      if (_remoteStream != null) {
        for (final track in _remoteStream!.getTracks()) {
          await track.stop();
        }
        await _remoteStream!.dispose();
        _remoteStream = null;
      }

      if (_peerConnection != null) {
        await _peerConnection!.close();
        await _peerConnection!.dispose();
        _peerConnection = null;
      }

      if (_isInitialized) {
        localRenderer.srcObject = null;
        remoteRenderer.srcObject = null;
        await localRenderer.dispose();
        await remoteRenderer.dispose();
        _isInitialized = false;
      }
    } catch (_) {
      // Best-effort cleanup
    }
  }
}
