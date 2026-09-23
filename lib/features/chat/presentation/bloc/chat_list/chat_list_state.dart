import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_entity.dart';

abstract class ChatListState extends Equatable {
  final String sortBy;
  const ChatListState({this.sortBy = 'time'});

  @override
  List<Object?> get props => [sortBy];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {
  const ChatListLoading({super.sortBy});
}

class ChatListLoaded extends ChatListState {
  final List<ChatEntity> chats;
  const ChatListLoaded({required this.chats, super.sortBy});

  @override
  List<Object?> get props => [chats, sortBy];
}

class ChatListError extends ChatListState {
  final String message;
  const ChatListError(this.message, {super.sortBy});

  @override
  List<Object?> get props => [message, sortBy];
}
