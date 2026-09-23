import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/appearance_cubit.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../calls/domain/entities/call_entity.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../bloc/chat_room/chat_room_bloc.dart';
import '../bloc/chat_room/chat_room_event.dart';
import '../bloc/chat_room/chat_room_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final ChatEntity? chat;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    this.chat,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  late ChatRoomBloc _chatRoomBloc;
  MessageEntity? _replyingMessage;

  @override
  void initState() {
    super.initState();
    _chatRoomBloc = getIt<ChatRoomBloc>();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      _chatRoomBloc.add(
        LoadMessagesEvent(
          chatId: widget.chatId,
          currentUserId: authState.user.uid,
        ),
      );
    }
  }

  @override
  void dispose() {
    _chatRoomBloc.close();
    super.dispose();
  }

  void _handleSendText(String content) {
    _chatRoomBloc.add(
      SendTextMessageEvent(
        chatId: widget.chatId,
        content: content,
        replyTo: _replyingMessage != null
            ? {
                'messageId': _replyingMessage!.messageId,
                'senderName': _replyingMessage!.senderName,
                'text': _replyingMessage!.content,
              }
            : null,
      ),
    );
    setState(() => _replyingMessage = null);
  }

  void _handleSendMedia(String filePath, String fileName, String type) {
    _chatRoomBloc.add(
      SendMediaMessageEvent(
        chatId: widget.chatId,
        filePath: filePath,
        fileName: fileName,
        type: type,
        replyTo: _replyingMessage != null
            ? {
                'messageId': _replyingMessage!.messageId,
                'senderName': _replyingMessage!.senderName,
                'text': _replyingMessage!.content,
              }
            : null,
      ),
    );
    setState(() => _replyingMessage = null);
  }

  void _handleDelete(String messageId, String currentUserId, bool forEveryone) {
    _chatRoomBloc.add(
      DeleteMessageEvent(
        chatId: widget.chatId,
        messageId: messageId,
        currentUserId: currentUserId,
        forEveryone: forEveryone,
      ),
    );
  }

  void _initiateCall(String type) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) return;

    if (widget.chat == null || widget.chat!.isGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group calling is not supported yet (1-on-1 calls only).')),
      );
      return;
    }

    final currentUserId = authState.user.uid;
    final otherUserId = widget.chat!.getOtherUserId(currentUserId);
    if (otherUserId.isEmpty) return;

    final otherUserName = widget.chat!.getDisplayName(currentUserId);
    final otherUserPhoto = widget.chat!.getDisplayPhoto(currentUserId);

    final newCall = CallEntity(
      callId: const Uuid().v4(),
      callerId: currentUserId,
      callerName: authState.user.displayName.isNotEmpty
          ? authState.user.displayName
          : 'LightChat User',
      callerPhoto: authState.user.photoUrl,
      receiverId: otherUserId,
      receiverName: otherUserName,
      receiverPhoto: otherUserPhoto,
      type: type,
      status: 'calling',
      createdAt: DateTime.now(),
    );

    context.push('/call', extra: {
      'call': newCall,
      'isCaller': true,
      'currentUserId': currentUserId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthenticatedState ? authState.user.uid : '';

    final displayName = widget.chat?.getDisplayName(currentUserId) ?? 'Chat';
    final photoUrl = widget.chat?.getDisplayPhoto(currentUserId);
    final isOnline = widget.chat?.isOtherUserOnline(currentUserId) ?? false;
    final isGroup = widget.chat?.isGroup ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            // Future: Navigate to contact or group details
          },
          child: Row(
            children: [
              CustomAvatar(
                imageUrl: photoUrl,
                name: displayName,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.heading3.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isGroup
                          ? '${widget.chat?.participants.length ?? 0} members'
                          : (isOnline ? 'online' : 'offline'),
                      style: AppTextStyles.caption.copyWith(
                        color: isOnline ? AppColors.onlineIndicator : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () => _initiateCall('video'),
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () => _initiateCall('voice'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.surface,
            onSelected: (val) {
              if (val == 'clear') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat options')),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'info',
                child: Text(isGroup ? 'Group info' : 'Contact info'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear chat'),
              ),
            ],
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final appearance = context.watch<AppearanceCubit?>()?.state;
          final wallpaperType = appearance?.wallpaperType ?? 'default';
          final customPath = appearance?.customWallpaperPath;

          BoxDecoration bgDecoration;
          if (wallpaperType == 'solid_dark') {
            bgDecoration = const BoxDecoration(color: Color(0xFF0B141B));
          } else if (wallpaperType == 'solid_forest') {
            bgDecoration = const BoxDecoration(color: Color(0xFF06201B));
          } else if (wallpaperType == 'custom' && customPath != null && File(customPath).existsSync()) {
            bgDecoration = BoxDecoration(
              image: DecorationImage(
                image: FileImage(File(customPath)),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
              ),
            );
          } else {
            bgDecoration = const BoxDecoration(color: AppColors.background);
          }

          return Container(
            decoration: bgDecoration,
            child: Column(
              children: [
                Expanded(
                  child: BlocBuilder<ChatRoomBloc, ChatRoomState>(
                    bloc: _chatRoomBloc,
                    builder: (context, state) {
                if (state is ChatRoomLoading) {
                  return const LoadingIndicator();
                } else if (state is ChatRoomError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                } else if (state is ChatRoomLoaded) {
                  if (state.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.waving_hand_rounded, size: 48, color: AppColors.primary),
                          const SizedBox(height: 12),
                          Text(
                            'Say hello to start the conversation! 👋',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      return MessageBubble(
                        message: message,
                        currentUserId: currentUserId,
                        isGroup: isGroup,
                        onReply: () => setState(() => _replyingMessage = message),
                        onDelete: (forEveryone) => _handleDelete(message.messageId, currentUserId, forEveryone),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          MessageInput(
            replyingMessage: _replyingMessage,
            onCancelReply: () => setState(() => _replyingMessage = null),
            onSend: _handleSendText,
            onSendMedia: _handleSendMedia,
            onTypingChanged: (isTyping) {
              _chatRoomBloc.add(
                SetTypingEvent(
                  chatId: widget.chatId,
                  userId: currentUserId,
                  isTyping: isTyping,
                ),
              );
            },
          ),
        ],
      ),
    );
  },
),
    );
  }
}
