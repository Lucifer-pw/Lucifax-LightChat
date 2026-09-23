import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/chat_entity.dart';
import '../../../domain/usecases/get_chats_stream.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final GetChatsStream getChatsStream;
  StreamSubscription<List<ChatEntity>>? _chatsSubscription;
  List<ChatEntity> _rawChats = [];
  String _currentSortBy = 'time';
  String _currentUserId = '';

  ChatListBloc({required this.getChatsStream}) : super(ChatListInitial()) {
    on<LoadChatsEvent>(_onLoadChats);
    on<UpdateChatsListEvent>(_onUpdateChatsList);
    on<ChangeSortFilterEvent>(_onChangeSortFilter);
  }

  void _onLoadChats(LoadChatsEvent event, Emitter<ChatListState> emit) {
    emit(ChatListLoading(sortBy: _currentSortBy));
    _currentUserId = event.userId;
    _chatsSubscription?.cancel();

    _chatsSubscription = getChatsStream(
      userId: event.userId,
      type: event.type,
    ).listen(
      (chats) => add(UpdateChatsListEvent(chats)),
      onError: (err) => emit(ChatListError(err.toString(), sortBy: _currentSortBy)),
    );
  }

  void _onUpdateChatsList(UpdateChatsListEvent event, Emitter<ChatListState> emit) {
    _rawChats = event.chats;
    final sorted = _sortChats(_rawChats, _currentSortBy);
    emit(ChatListLoaded(chats: sorted, sortBy: _currentSortBy));
  }

  void _onChangeSortFilter(ChangeSortFilterEvent event, Emitter<ChatListState> emit) {
    _currentSortBy = event.sortBy;
    final sorted = _sortChats(_rawChats, _currentSortBy);
    emit(ChatListLoaded(chats: sorted, sortBy: _currentSortBy));
  }

  List<ChatEntity> _sortChats(List<ChatEntity> list, String sortBy) {
    final copy = List<ChatEntity>.from(list);
    if (sortBy == 'unread') {
      copy.sort((a, b) {
        final unreadA = a.getUnreadCount(_currentUserId);
        final unreadB = b.getUnreadCount(_currentUserId);
        if (unreadA != unreadB) {
          return unreadB.compareTo(unreadA); // Higher unread on top
        }
        final timeA = a.updatedAt ?? DateTime(2000);
        final timeB = b.updatedAt ?? DateTime(2000);
        return timeB.compareTo(timeA);
      });
    } else {
      // Sort by time
      copy.sort((a, b) {
        final timeA = a.updatedAt ?? DateTime(2000);
        final timeB = b.updatedAt ?? DateTime(2000);
        return timeB.compareTo(timeA);
      });
    }
    return copy;
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    return super.close();
  }
}
