import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/media_storage_service.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/usecases/delete_message.dart';
import '../../../domain/usecases/get_messages_stream.dart';
import '../../../domain/usecases/mark_as_read.dart';
import '../../../domain/usecases/purge_storage_media.dart';
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
  final PurgeStorageMedia purgeStorageMedia;
  final MediaStorageService mediaStorageService;
  StreamSubscription<List<MessageEntity>>? _messagesSubscription;

  // Track downloading message IDs to prevent duplicate downloads
  final Set<String> _activeDownloadingMessageIds = {};

  ChatRoomBloc({
    required this.getMessagesStream,
    required this.sendMessage,
    required this.markAsRead,
    required this.setTypingStatus,
    required this.uploadChatMedia,
    required this.deleteMessage,
    required this.purgeStorageMedia,
    required this.mediaStorageService,
  }) : super(ChatRoomInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<MessagesUpdatedEvent>(_onMessagesUpdated);
    on<SendTextMessageEvent>(_onSendTextMessage);
    on<SendMediaMessageEvent>(_onSendMediaMessage);
    on<DownloadAndPurgeMediaEvent>(_onDownloadAndPurgeMedia);
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

        // Auto-download incoming images to internal-media & purge from storage
        for (final msg in filtered) {
          if (msg.senderId != event.currentUserId &&
              msg.type == 'image' &&
              !msg.isDeleted &&
              msg.mediaInfo != null) {
            final isPurged = msg.mediaInfo!['isPurgedFromStorage'] == true;
            final storagePath = msg.mediaInfo!['storagePath'] as String? ?? '';
            final fileName = msg.mediaInfo!['fileName'] as String? ?? '';

            if (!isPurged && storagePath.isNotEmpty && fileName.isNotEmpty) {
              if (_activeDownloadingMessageIds.add(msg.messageId)) {
                _checkAndAutoDownload(event.chatId, msg, storagePath, fileName);
              }
            }
          }
        }

        add(MessagesUpdatedEvent(filtered));
      },
      onError: (err) => emit(ChatRoomError(err.toString())),
    );
  }

  Future<void> _checkAndAutoDownload(
    String chatId,
    MessageEntity msg,
    String storagePath,
    String fileName,
  ) async {
    final existingLocalPath = await mediaStorageService.findLocalFile(fileName, msg.type);
    if (existingLocalPath == null) {
      add(
        DownloadAndPurgeMediaEvent(
          chatId: chatId,
          messageId: msg.messageId,
          storagePath: storagePath,
          downloadUrl: msg.content,
          fileName: fileName,
          type: msg.type,
        ),
      );
    }
  }

  List<MessageEntity> _currentMessages = [];

  void _onMessagesUpdated(MessagesUpdatedEvent event, Emitter<ChatRoomState> emit) {
    _currentMessages = event.messages;
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
    // 1. Save locally to internal-media first
    String? localSavedPath;
    try {
      final savedFile = await mediaStorageService.saveSentMedia(
        sourceFilePath: event.filePath,
        targetFileName: event.fileName,
        type: event.type,
      );
      localSavedPath = savedFile.path;
    } catch (_) {}

    // 2. Upload to ephemeral gateway in Firebase Storage
    final uploadResult = await uploadChatMedia(
      chatId: event.chatId,
      filePath: event.filePath,
      fileName: event.fileName,
    );

    await uploadResult.fold(
      (failure) async {
        emit(ChatRoomLoaded(
          _currentMessages,
          errorMessage: 'Gagal mengunggah media: ${failure.message}. Periksa koneksi atau izin Firebase Storage.',
        ));
      },
      (uploadData) async {
        final downloadUrl = uploadData['downloadUrl'] as String? ?? '';
        final storagePath = uploadData['storagePath'] as String? ?? '';
        final fileSize = uploadData['fileSize'] as int? ?? 0;

        await sendMessage(
          chatId: event.chatId,
          content: downloadUrl,
          type: event.type,
          mediaInfo: {
            'fileName': event.fileName,
            'caption': event.caption,
            'storagePath': storagePath,
            'fileSize': fileSize,
            'localPath': localSavedPath,
            'isPurgedFromStorage': false,
          },
          replyTo: event.replyTo,
        );
      },
    );
  }

  Future<void> _onDownloadAndPurgeMedia(
    DownloadAndPurgeMediaEvent event,
    Emitter<ChatRoomState> emit,
  ) async {
    if (_activeDownloadingMessageIds.contains(event.messageId)) return;
    _activeDownloadingMessageIds.add(event.messageId);

    try {
      // 1. Download to internal-media
      final downloadedFile = await mediaStorageService.downloadMedia(
        url: event.downloadUrl,
        targetFileName: event.fileName,
        type: event.type,
      );

      // 2. Once downloaded to device, PURGE from Firebase Storage
      if (downloadedFile != null) {
        await purgeStorageMedia(
          chatId: event.chatId,
          messageId: event.messageId,
          storagePath: event.storagePath,
        );
      }
    } finally {
      _activeDownloadingMessageIds.remove(event.messageId);
    }
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
