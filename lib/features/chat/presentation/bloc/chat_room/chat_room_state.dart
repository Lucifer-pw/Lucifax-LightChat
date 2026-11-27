import 'package:equatable/equatable.dart';
import '../../../domain/entities/message_entity.dart';

abstract class ChatRoomState extends Equatable {
  const ChatRoomState();

  @override
  List<Object?> get props => [];
}

class ChatRoomInitial extends ChatRoomState {}

class ChatRoomLoading extends ChatRoomState {}

class ChatRoomLoaded extends ChatRoomState {
  final List<MessageEntity> messages;
  final String? errorMessage;

  const ChatRoomLoaded(this.messages, {this.errorMessage});

  @override
  List<Object?> get props => [messages, errorMessage];
}

class ChatRoomError extends ChatRoomState {
  final String message;
  const ChatRoomError(this.message);

  @override
  List<Object?> get props => [message];
}
