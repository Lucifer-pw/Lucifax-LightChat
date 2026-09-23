import 'dart:async';
import 'package:equatable/equatable.dart';
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

class IncomingCallRinging extends IncomingCallState {
  final CallEntity call;

  const IncomingCallRinging(this.call);

  @override
  List<Object?> get props => [call];
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
    if (_currentUserId == userId && _incomingCallsSub != null) return;
    _currentUserId = userId;

    _incomingCallsSub?.cancel();
    _incomingCallsSub = getIncomingCallsStream.call(userId).listen(
      (calls) {
        if (calls.isNotEmpty) {
          // Find the most recent active incoming call
          final activeCall = calls.firstWhere(
            (c) => c.status == 'calling',
            orElse: () => calls.first,
          );
          if (activeCall.status == 'calling') {
            emit(IncomingCallRinging(activeCall));
          } else {
            emit(IncomingCallIdle());
          }
        } else {
          emit(IncomingCallIdle());
        }
      },
      onError: (_) {
        emit(IncomingCallIdle());
      },
    );
  }

  void stopListening() {
    _incomingCallsSub?.cancel();
    _incomingCallsSub = null;
    _currentUserId = null;
    emit(IncomingCallIdle());
  }

  Future<void> rejectIncomingCall(String callId) async {
    emit(IncomingCallIdle());
    await endCallUseCase.call(callId, status: 'rejected');
  }

  void clearIncomingCall() {
    emit(IncomingCallIdle());
  }

  @override
  Future<void> close() {
    _incomingCallsSub?.cancel();
    return super.close();
  }
}
