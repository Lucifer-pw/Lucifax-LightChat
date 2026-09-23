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
  const ChatRoomLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatRoomError extends ChatRoomState {
  final String message;
  const ChatRoomError(this.message);

  @override
  List<Object?> get props => [message];
}
