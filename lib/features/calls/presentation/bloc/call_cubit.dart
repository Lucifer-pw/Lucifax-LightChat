import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/webrtc_service.dart';
import '../../domain/entities/call_entity.dart';
import '../../domain/repositories/call_repository.dart';
import '../../domain/usecases/answer_call.dart';
import '../../domain/usecases/end_call.dart';
import '../../domain/usecases/get_call_stream.dart';
import '../../domain/usecases/make_call.dart';
import 'call_state.dart';

class CallCubit extends Cubit<CallState> {
  final WebRTCService webrtcService;
  final MakeCall makeCallUseCase;
  final AnswerCall answerCallUseCase;
  final EndCall endCallUseCase;
  final GetCallStream getCallStreamUseCase;
  final CallRepository callRepository;

  StreamSubscription<CallEntity?>? _callSub;
  StreamSubscription<List<Map<String, dynamic>>>? _candidatesSub;
  Timer? _timer;
  final Set<String> _processedCandidateIds = {};

  CallCubit({
    required this.webrtcService,
    required this.makeCallUseCase,
    required this.answerCallUseCase,
    required this.endCallUseCase,
    required this.getCallStreamUseCase,
    required this.callRepository,
  }) : super(const CallState());

  Future<void> startCall({required CallEntity call}) async {
    try {
      emit(state.copyWith(
        status: CallStatus.connecting,
        call: call,
        isCaller: true,
        isSpeakerOn: call.isVideo,
      ));

      // 1. Initialize local camera / mic
      await webrtcService.openUserMedia(isVideo: call.isVideo);
      await webrtcService.setSpeakerphone(call.isVideo);

      // 2. Create WebRTC Offer
      final offer = await webrtcService.createOffer(isVideo: call.isVideo);

      // 3. Save call to Firestore
      final makeCallResult = await makeCallUseCase.call(call, offer);

      makeCallResult.fold(
        (failure) {
          emit(state.copyWith(
            status: CallStatus.error,
            errorMessage: failure.message,
          ));
        },
        (callId) {
          emit(state.copyWith(status: CallStatus.calling));

          // 4. Send local ICE candidates to Firestore
          webrtcService.onIceCandidate = (candidate) {
            callRepository.addCandidate(
              call.callId,
              'callerCandidates',
              candidate.toMap(),
            );
          };

          // 5. Listen for remote stream
          webrtcService.onRemoteStream = (stream) {
            emit(state.copyWith(isRemoteVideoActive: stream.getVideoTracks().isNotEmpty));
          };

          // 6. Listen for receiver candidates
          _listenToCandidates(call.callId, 'receiverCandidates');

          // 7. Listen for call updates from receiver (answer / reject)
          _listenToCallDocument(call.callId);
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CallStatus.error,
        errorMessage: 'Failed to start call: $e',
      ));
    }
  }

  Future<void> acceptCall({required CallEntity call}) async {
    try {
      emit(state.copyWith(
        status: CallStatus.connecting,
        call: call,
        isCaller: false,
        isSpeakerOn: call.isVideo,
      ));

      // 1. Initialize local camera / mic
      await webrtcService.openUserMedia(isVideo: call.isVideo);
      await webrtcService.setSpeakerphone(call.isVideo);

      // 2. Create peer connection instance & set remote offer
      await webrtcService.createPeerConnectionInstance(isVideo: call.isVideo);
      if (call.offer != null) {
        await webrtcService.setRemoteDescription(call.offer!);
      }

      // 3. Create WebRTC Answer
      final answer = await webrtcService.createAnswer(isVideo: call.isVideo);

      // 4. Save answer to Firestore & set status to connected
      final answerResult = await answerCallUseCase.call(call.callId, answer);

      answerResult.fold(
        (failure) {
          emit(state.copyWith(
            status: CallStatus.error,
            errorMessage: failure.message,
          ));
        },
        (_) {
          emit(state.copyWith(status: CallStatus.connected));
          _startDurationTimer();

          // 5. Send local ICE candidates
          webrtcService.onIceCandidate = (candidate) {
            callRepository.addCandidate(
              call.callId,
              'receiverCandidates',
              candidate.toMap(),
            );
          };

          // 6. Listen for remote stream
          webrtcService.onRemoteStream = (stream) {
            emit(state.copyWith(isRemoteVideoActive: stream.getVideoTracks().isNotEmpty));
          };

          // 7. Listen for caller candidates
          _listenToCandidates(call.callId, 'callerCandidates');

          // 8. Listen for call termination
          _listenToCallDocument(call.callId);
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: CallStatus.error,
        errorMessage: 'Failed to accept call: $e',
      ));
    }
  }

  void _listenToCandidates(String callId, String candidateType) {
    _candidatesSub?.cancel();
    _candidatesSub = callRepository.getCandidatesStream(callId, candidateType).listen(
      (candidates) {
        for (final candidateMap in candidates) {
          final candidateStr = candidateMap['candidate']?.toString() ?? '';
          if (candidateStr.isNotEmpty && !_processedCandidateIds.contains(candidateStr)) {
            _processedCandidateIds.add(candidateStr);
            webrtcService.addCandidate(candidateMap);
          }
        }
      },
    );
  }

  void _listenToCallDocument(String callId) {
    _callSub?.cancel();
    _callSub = getCallStreamUseCase.call(callId).listen(
      (call) async {
        if (call == null) return;

        // Caller received answer
        if (state.isCaller &&
            call.answer != null &&
            state.status != CallStatus.connected &&
            !call.isEnded) {
          await webrtcService.setRemoteDescription(call.answer!);
          emit(state.copyWith(
            status: CallStatus.connected,
            call: call,
          ));
          _startDurationTimer();
        }

        // Call status changes to ended / rejected / busy
        if (call.isEnded && state.status != CallStatus.ended) {
          _cleanUpResources();
          emit(state.copyWith(
            status: CallStatus.ended,
            call: call,
          ));
        }
      },
    );
  }

  void _startDurationTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!isClosed) {
        emit(state.copyWith(duration: state.duration + 1));
      }
    });
  }

  void toggleMicrophone() {
    final nextState = !state.isMuted;
    webrtcService.toggleMicrophone(nextState);
    emit(state.copyWith(isMuted: nextState));
  }

  void toggleVideo() {
    final nextState = !state.isVideoOff;
    webrtcService.toggleVideo(nextState);
    emit(state.copyWith(isVideoOff: nextState));
  }

  Future<void> switchCamera() async {
    await webrtcService.switchCamera();
    emit(state.copyWith(isFrontCamera: !state.isFrontCamera));
  }

  Future<void> toggleSpeakerphone() async {
    final nextState = !state.isSpeakerOn;
    await webrtcService.setSpeakerphone(nextState);
    emit(state.copyWith(isSpeakerOn: nextState));
  }

  Future<void> endCall({String status = 'ended'}) async {
    final currentCall = state.call;
    final duration = state.duration;

    _cleanUpResources();
    emit(state.copyWith(status: CallStatus.ended));

    if (currentCall != null) {
      await endCallUseCase.call(
        currentCall.callId,
        status: status,
        duration: duration,
      );
    }
  }

  void _cleanUpResources() {
    _timer?.cancel();
    _timer = null;
    _callSub?.cancel();
    _callSub = null;
    _candidatesSub?.cancel();
    _candidatesSub = null;
    _processedCandidateIds.clear();
    webrtcService.dispose();
  }

  @override
  Future<void> close() {
    _cleanUpResources();
    return super.close();
  }
}
