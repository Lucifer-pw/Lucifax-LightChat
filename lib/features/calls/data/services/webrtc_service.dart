import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _hasRemoteDescription = false;
  final List<RTCIceCandidate> _candidateQueue = [];

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      {'urls': 'stun:stun.services.mozilla.com'},
      {'urls': 'stun:global.stun.twilio.com:3478'},
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

  Future<bool> requestPermissions({required bool isVideo}) async {
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      debugPrint('[WebRTCService] Microphone permission not granted: $micStatus');
      return false;
    }

    if (isVideo) {
      final camStatus = await Permission.camera.request();
      if (camStatus != PermissionStatus.granted) {
        debugPrint('[WebRTCService] Camera permission not granted: $camStatus');
        return false;
      }
    }

    // Request Bluetooth connect permission on Android 12+ for Bluetooth earphones/speakers
    try {
      final btStatus = await Permission.bluetoothConnect.status;
      if (!btStatus.isGranted) {
        await Permission.bluetoothConnect.request();
      }
    } catch (e) {
      debugPrint('[WebRTCService] Bluetooth permission check note: $e');
    }

    return true;
  }

  Future<MediaStream> openUserMedia({required bool isVideo}) async {
    await requestPermissions(isVideo: isVideo);
    await initializeRenderers();

    final mediaConstraints = <String, dynamic>{
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'highpassFilter': true,
      },
      'video': isVideo
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    // Ensure all audio tracks are enabled and at full volume
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = true;
    }

    if (isVideo) {
      localRenderer.srcObject = _localStream;
    }

    return _localStream!;
  }

  Future<void> createPeerConnectionInstance({required bool isVideo}) async {
    if (_peerConnection != null) return;

    _hasRemoteDescription = false;
    _candidateQueue.clear();

    _peerConnection = await createPeerConnection(_iceServers, _config);

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        debugPrint('[WebRTCService] Local ICE candidate generated: ${candidate.candidate}');
        onIceCandidate?.call(candidate);
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) async {
      debugPrint('[WebRTCService] onTrack received: ${event.track.kind}, streams: ${event.streams.length}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
      } else {
        _remoteStream ??= await createLocalMediaStream('remote_stream');
        await _remoteStream!.addTrack(event.track);
      }

      // Ensure remote audio track is enabled
      if (event.track.kind == 'audio') {
        event.track.enabled = true;
      }

      remoteRenderer.srcObject = _remoteStream;
      if (_remoteStream != null) {
        onRemoteStream?.call(_remoteStream!);
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('[WebRTCService] Connection state changed: $state');
      onConnectionState?.call(state);
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('[WebRTCService] ICE connection state changed: $state');
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
      _hasRemoteDescription = true;
      debugPrint('[WebRTCService] Remote description set. Draining ${_candidateQueue.length} queued candidates...');

      // Drain all queued candidates that arrived before remote description was set
      for (final candidate in _candidateQueue) {
        try {
          await _peerConnection!.addCandidate(candidate);
          debugPrint('[WebRTCService] Drained queued candidate: ${candidate.candidate}');
        } catch (e) {
          debugPrint('[WebRTCService] Error adding queued candidate: $e');
        }
      }
      _candidateQueue.clear();
    }
  }

  Future<void> addCandidate(Map<String, dynamic> candidateMap) async {
    final candidateStr = candidateMap['candidate']?.toString() ?? '';
    if (candidateStr.isEmpty) return;

    final candidate = RTCIceCandidate(
      candidateStr,
      candidateMap['sdpMid']?.toString(),
      (candidateMap['sdpMLineIndex'] as num?)?.toInt(),
    );

    if (_peerConnection != null && _hasRemoteDescription) {
      try {
        await _peerConnection!.addCandidate(candidate);
        debugPrint('[WebRTCService] Direct added ICE candidate: $candidateStr');
      } catch (e) {
        debugPrint('[WebRTCService] Error adding ICE candidate: $e');
      }
    } else {
      _candidateQueue.add(candidate);
      debugPrint('[WebRTCService] Queued ICE candidate (waiting for remote desc): $candidateStr');
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
    try {
      await Helper.ensureAudioSession();
      await Helper.setSpeakerphoneOn(enable);
      if (!enable) {
        await Helper.setSpeakerphoneOnButPreferBluetooth();
      }
    } catch (e) {
      debugPrint('[WebRTCService] Error setting speakerphone: $e');
    }
  }

  Future<void> dispose() async {
    try {
      _hasRemoteDescription = false;
      _candidateQueue.clear();

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
