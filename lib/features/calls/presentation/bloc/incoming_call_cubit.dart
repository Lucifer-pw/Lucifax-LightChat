import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/call_entity.dart';
import '../../domain/usecases/end_call.dart';
import '../../domain/usecases/get_incoming_calls_stream.dart';

abstract class IncomingCallState extends Equatable {
  const IncomingCallState();

  @override
  List<Object?> get props => [];
}

class IncomingCallIdle extends IncomingCallState {}

class IncomingCallListening extends IncomingCallState {}

class IncomingCallRinging extends IncomingCallState {
  final CallEntity call;
  final int _timestamp;

  IncomingCallRinging(this.call)
      : _timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [call.callId, _timestamp];
}

class IncomingCallError extends IncomingCallState {
  final String message;

  const IncomingCallError(this.message);

  @override
  List<Object?> get props => [message];
}

class IncomingCallCubit extends Cubit<IncomingCallState> {
  final GetIncomingCallsStream getIncomingCallsStream;
  final EndCall endCallUseCase;

  StreamSubscription<List<CallEntity>>? _incomingCallsSub;
  String? _currentUserId;

  IncomingCallCubit({
    required this.getIncomingCallsStream,
    required this.endCallUseCase,
  }) : super(IncomingCallIdle());

  void listenToIncomingCalls(String userId) {
    if (_currentUserId == userId && _incomingCallsSub != null) {
      debugPrint('[IncomingCallCubit] Already listening for userId=$userId');
      return;
    }
    _currentUserId = userId;
    debugPrint('[IncomingCallCubit] START listening, userId=$userId');

    _incomingCallsSub?.cancel();

    try {
      _incomingCallsSub = getIncomingCallsStream.call(userId).listen(
        (calls) {
          debugPrint('[IncomingCallCubit] Stream data: ${calls.length} calls');

          final activeCalls = calls
              .where((c) => c.status == 'calling' && c.receiverId == userId)
              .toList();

          debugPrint('[IncomingCallCubit] Active incoming calls: ${activeCalls.length}');

          if (activeCalls.isNotEmpty) {
            final activeCall = activeCalls.first;
            debugPrint('[IncomingCallCubit] RINGING callId=${activeCall.callId}, caller=${activeCall.callerName}');
            emit(IncomingCallRinging(activeCall));
          } else {
            // Only emit Listening (not Idle) to indicate the stream is active
            if (state is! IncomingCallListening) {
              emit(IncomingCallListening());
            }
          }
        },
        onError: (error) {
          debugPrint('[IncomingCallCubit] Stream ERROR: $error');
          emit(IncomingCallError('Stream error: $error'));
        },
      );

      // Emit Listening to confirm subscription was created successfully
      emit(IncomingCallListening());
    } catch (e) {
      debugPrint('[IncomingCallCubit] CATCH error: $e');
      emit(IncomingCallError('Setup error: $e'));
    }
  }

  void stopListening() {
    debugPrint('[IncomingCallCubit] stopListening');
    _incomingCallsSub?.cancel();
    _incomingCallsSub = null;
    _currentUserId = null;
    emit(IncomingCallIdle());
  }

  Future<void> rejectIncomingCall(String callId) async {
    emit(IncomingCallListening());
    await endCallUseCase.call(callId, status: 'rejected');
  }

  void clearIncomingCall() {
    emit(IncomingCallListening());
  }

  @override
  Future<void> close() {
    _incomingCallsSub?.cancel();
    return super.close();
  }
}
