import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/chat_entity.dart';
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

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthenticatedState ? authState.user.uid : '';

    final displayName = widget.chat?.getDisplayName(currentUserId) ?? 'Chat';
    final photoUrl = widget.chat?.getDisplayPhoto(currentUserId);
    final isOnline = widget.chat?.isOtherUserOnline(currentUserId) ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
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
                    isOnline ? 'online' : 'offline',
                    style: AppTextStyles.caption.copyWith(
                      color: isOnline ? AppColors.onlineIndicator : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
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
                      child: Text(
                        'Say hello to start the conversation! 👋',
                        style: AppTextStyles.bodySmall,
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
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          MessageInput(
            onSend: (content) {
              _chatRoomBloc.add(
                SendTextMessageEvent(
                  chatId: widget.chatId,
                  content: content,
                ),
              );
            },
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
  }
}
