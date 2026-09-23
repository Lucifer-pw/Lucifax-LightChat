import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_entity.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object?> get props => [];
}

class LoadChatsEvent extends ChatListEvent {
  final String userId;
  final String type; // "private" | "group"
  const LoadChatsEvent({required this.userId, required this.type});

  @override
  List<Object?> get props => [userId, type];
}

class UpdateChatsListEvent extends ChatListEvent {
  final List<ChatEntity> chats;
  const UpdateChatsListEvent(this.chats);

  @override
  List<Object?> get props => [chats];
}

class ChangeSortFilterEvent extends ChatListEvent {
  final String sortBy; // "time" | "unread"
  const ChangeSortFilterEvent(this.sortBy);

  @override
  List<Object?> get props => [sortBy];
}
