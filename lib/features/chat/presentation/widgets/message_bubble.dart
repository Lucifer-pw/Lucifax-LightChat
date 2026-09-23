import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/appearance_cubit.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/message_entity.dart';
import 'message_status_icon.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final String currentUserId;
  final bool isGroup;
  final VoidCallback? onReply;
  final void Function(bool forEveryone)? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.isGroup = false,
    this.onReply,
    this.onDelete,
  });

  void _showOptions(BuildContext context, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: AppColors.primary),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                onReply?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: AppColors.textSecondary),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied to clipboard')),
                );
              },
            ),
            if (onDelete != null) ...[
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('Delete for me'),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete?.call(false);
                },
              ),
              if (isMe && !message.isDeleted)
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                  title: const Text('Delete for everyone'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete?.call(true);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.isSentByMe(currentUserId);
    final isDeleted = message.isDeleted;

    final appearance = context.watch<AppearanceCubit?>()?.state;
    final sentColor = appearance?.sentBubbleColor ?? AppColors.bubbleSent;
    final isRounded = (appearance?.bubbleStyle ?? 'rounded') == 'rounded';
    final radiusVal = isRounded ? AppSizes.r12 : 4.0;

    return GestureDetector(
      onLongPress: isDeleted ? null : () => _showOptions(context, isMe),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          decoration: BoxDecoration(
            color: isMe ? sentColor : AppColors.bubbleReceived,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radiusVal),
              topRight: Radius.circular(radiusVal),
              bottomLeft: Radius.circular(isMe ? radiusVal : 0),
              bottomRight: Radius.circular(isMe ? 0 : radiusVal),
            ),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Group sender name
              if (isGroup && !isMe && !isDeleted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // Reply preview banner
              if (message.replyTo != null && !isDeleted)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: const Border(
                      left: BorderSide(color: AppColors.primary, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.replyTo!['senderName'] ?? 'Reply',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        message.replyTo!['text'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),

              // Message Content
              if (isDeleted)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.block_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'This message was deleted',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildContent(context, isMe),

              const SizedBox(height: 2),

              // Timestamp & Status Icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppDateFormatter.formatMessageTime(message.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (isMe && !isDeleted) ...[
                    const SizedBox(width: 4),
                    MessageStatusIcon(
                      status: message.status,
                      size: 13,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isMe) {
    if (message.type == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: message.content,
              fit: BoxFit.cover,
              width: 240,
              height: 180,
              placeholder: (context, url) => Container(
                width: 240,
                height: 180,
                color: AppColors.surfaceLight,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Container(
                width: 240,
                height: 180,
                color: AppColors.surfaceLight,
                child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
              ),
            ),
          ),
          if (message.mediaInfo?['caption'] != null && message.mediaInfo!['caption'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                message.mediaInfo!['caption'],
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isMe ? AppColors.bubbleSentText : AppColors.bubbleReceivedText,
                ),
              ),
            ),
        ],
      );
    } else if (message.type == 'file') {
      final fileName = message.mediaInfo?['fileName'] ?? 'Document';
      final fileSize = message.mediaInfo?['fileSize'];
      final formattedSize = fileSize != null ? '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB' : '';

      return InkWell(
        onTap: () {
          if (message.content.isNotEmpty) {
            launchUrl(Uri.parse(message.content), mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (formattedSize.isNotEmpty)
                      Text(
                        formattedSize,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      );
    } else if (message.type == 'audio' || message.type == 'voice') {
      final fileName = message.mediaInfo?['fileName'] ?? 'Audio message';
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 36),
              onPressed: () {
                if (message.content.isNotEmpty) {
                  launchUrl(Uri.parse(message.content), mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Text('Audio file', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default text message
    return Text(
      message.content,
      style: AppTextStyles.bodyMedium.copyWith(
        color: isMe ? AppColors.bubbleSentText : AppColors.bubbleReceivedText,
        height: 1.3,
      ),
    );
  }
}
