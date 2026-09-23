import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/message_entity.dart';
import 'media_picker_sheet.dart';

class MessageInput extends StatefulWidget {
  final ValueChanged<String> onSend;
  final void Function(String filePath, String fileName, String type)? onSendMedia;
  final ValueChanged<bool>? onTypingChanged;
  final MessageEntity? replyingMessage;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    required this.onSend,
    this.onSendMedia,
    this.onTypingChanged,
    this.replyingMessage,
    this.onCancelReply,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
        widget.onTypingChanged?.call(hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    widget.onTypingChanged?.call(false);
  }

  Future<void> _openMediaPicker() async {
    final result = await MediaPickerSheet.show(context);
    if (result != null && widget.onSendMedia != null) {
      widget.onSendMedia!(result.path, result.name, result.type);
    }
  }

  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null && widget.onSendMedia != null) {
      widget.onSendMedia!(photo.path, photo.name, 'image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply Preview Banner
            if (widget.replyingMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceLight,
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.replyingMessage!.senderName,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.replyingMessage!.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                      onPressed: widget.onCancelReply,
                    ),
                  ],
                ),
              ),

            // Input Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.iconColor),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: AppTextStyles.bodyMedium,
                              maxLines: 4,
                              minLines: 1,
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => _handleSend(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.attach_file_rounded, color: AppColors.iconColor),
                            onPressed: _openMediaPicker,
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.iconColor),
                            onPressed: _openCamera,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSizes.hSpace8,
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _hasText ? Icons.send_rounded : Icons.mic_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _hasText ? _handleSend : _openMediaPicker,
                    ),
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
