import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/usecases/delete_message.dart';
import '../../../domain/usecases/get_messages_stream.dart';
import '../../../domain/usecases/mark_as_read.dart';
import '../../../domain/usecases/send_message.dart';
import '../../../domain/usecases/set_typing_status.dart';
import '../../../domain/usecases/upload_chat_media.dart';
import 'chat_room_event.dart';
import 'chat_room_state.dart';

class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final GetMessagesStream getMessagesStream;
  final SendMessage sendMessage;
  final MarkAsRead markAsRead;
  final SetTypingStatus setTypingStatus;
  final UploadChatMedia uploadChatMedia;
  final DeleteMessage deleteMessage;
  StreamSubscription<List<MessageEntity>>? _messagesSubscription;

  ChatRoomBloc({
    required this.getMessagesStream,
    required this.sendMessage,
    required this.markAsRead,
    required this.setTypingStatus,
    required this.uploadChatMedia,
    required this.deleteMessage,
  }) : super(ChatRoomInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<MessagesUpdatedEvent>(_onMessagesUpdated);
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendMediaMessageEvent>(_onSendMediaMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<MarkChatAsReadEvent>(_onMarkChatAsRead);
    on<SetTypingEvent>(_onSetTyping);
  }

  void _onLoadMessages(LoadMessagesEvent event, Emitter<ChatRoomState> emit) {
    emit(ChatRoomLoading());
    _messagesSubscription?.cancel();

    // Mark as read immediately when loading
    markAsRead(chatId: event.chatId, currentUserId: event.currentUserId);

    _messagesSubscription = getMessagesStream(event.chatId).listen(
      (messages) {
        // Filter out messages deleted for this user
        final filtered = messages.where((m) => !m.deletedFor.contains(event.currentUserId)).toList();

        // If there are unread messages sent by others, mark them as read in real-time
        final hasUnread = filtered.any((m) => m.senderId != event.currentUserId && m.status != 'read');
        if (hasUnread) {
          markAsRead(chatId: event.chatId, currentUserId: event.currentUserId);
        }

        add(MessagesUpdatedEvent(filtered));
      },
      onError: (err) => emit(ChatRoomError(err.toString())),
    );
  }

  void _onMessagesUpdated(MessagesUpdatedEvent event, Emitter<ChatRoomState> emit) {
    emit(ChatRoomLoaded(event.messages));
  }

  Future<void> _onSendTextMessage(
    SendTextMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    await sendMessage(
      chatId: event.chatId,
      content: event.content,
      type: 'text',
      replyTo: event.replyTo,
    );
  }

  Future<void> _onSendMediaMessage(
    SendMediaMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    final uploadResult = await uploadChatMedia(
      chatId: event.chatId,
      filePath: event.filePath,
      fileName: event.fileName,
    );

    await uploadResult.fold(
      (failure) async {
        // Handle upload failure
      },
      (mediaUrl) async {
        await sendMessage(
          chatId: event.chatId,
          content: mediaUrl,
          type: event.type,
          mediaInfo: {
            'fileName': event.fileName,
            'caption': event.caption,
          },
          replyTo: event.replyTo,
        );
      },
    );
  }

  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    await deleteMessage(
      chatId: event.chatId,
      messageId: event.messageId,
      currentUserId: event.currentUserId,
      forEveryone: event.forEveryone,
    );
  }

  Future<void> _onMarkChatAsRead(
    MarkChatAsReadEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    await markAsRead(chatId: event.chatId, currentUserId: event.currentUserId);
  }

  Future<void> _onSetTyping(
    SetTypingEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    await setTypingStatus(
      chatId: event.chatId,
      userId: event.userId,
      isTyping: event.isTyping,
    );
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
