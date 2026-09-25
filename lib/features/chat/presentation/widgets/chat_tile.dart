import 'package:flutter/material.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../domain/entities/chat_entity.dart';
import 'message_status_icon.dart';

class ChatTile extends StatelessWidget {
  final ChatEntity chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = chat.getDisplayName(currentUserId);
    final photoUrl = chat.getDisplayPhoto(currentUserId);
    final isOnline = chat.isOtherUserOnline(currentUserId);
    final unreadCount = chat.getUnreadCount(currentUserId);
    final lastMessage = chat.lastMessage;

    final lastMessageText = lastMessage?['text'] ?? '';
    final lastMessageSenderId = lastMessage?['senderId'];
    final isMeSender = lastMessageSenderId == currentUserId;
    final lastMessageStatus = lastMessage?['status']?.toString() ?? 'sent';
    final lastMessageTime = lastMessage?['timestamp'] != null
        ? (lastMessage!['timestamp'] as dynamic).toDate()
        : chat.updatedAt;

    final isTyping = chat.typingUsers.any((id) => id != currentUserId);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: 12),
        child: Row(
          children: [
            CustomAvatar(
              imageUrl: photoUrl,
              name: displayName,
              radius: 26,
              isOnline: isOnline,
              showOnlineBadge: !chat.isGroup,
              onTap: () {
                if (!chat.isGroup) {
                  final otherUserId = chat.getOtherUserId(currentUserId);
                  if (otherUserId.isNotEmpty) {
                    appRouter.push('/contact-profile', extra: {
                      'userId': otherUserId,
                      'displayName': displayName,
                      'photoUrl': photoUrl,
                      'phoneNumber': '',
                      'about': 'Available',
                    });
                  }
                }
              },
            ),
            AppSizes.hSpace16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: AppTextStyles.chatTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppDateFormatter.formatChatTime(lastMessageTime),
                        style: AppTextStyles.chatTime.copyWith(
                          color: unreadCount > 0 ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  AppSizes.vSpace4,
                  Row(
                    children: [
                      if (isMeSender && !isTyping) ...[
                        MessageStatusIcon(status: lastMessageStatus),
                        AppSizes.hSpace4,
                      ],
                      Expanded(
                        child: isTyping
                            ? Text(
                                'typing...',
                                style: AppTextStyles.chatSubtitle.copyWith(
                                  color: AppColors.primary,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                lastMessageText.isEmpty ? 'No messages yet' : lastMessageText,
                                style: AppTextStyles.chatSubtitle.copyWith(
                                  color: unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      if (unreadCount > 0) ...[
                        AppSizes.hSpace8,
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.unreadBadge,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Center(
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
