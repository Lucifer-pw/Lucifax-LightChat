import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/media_storage_service.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/message_entity.dart';
import '../bloc/chat_room/chat_room_bloc.dart';
import '../bloc/chat_room/chat_room_event.dart';

class MediaMessageView extends StatefulWidget {
  final MessageEntity message;
  final bool isMe;

  const MediaMessageView({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<MediaMessageView> createState() => _MediaMessageViewState();
}

class _MediaMessageViewState extends State<MediaMessageView> {
  String? _localFilePath;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _resolveLocalFile();
  }

  @override
  void didUpdateWidget(covariant MediaMessageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.content != widget.message.content ||
        oldWidget.message.mediaInfo != widget.message.mediaInfo) {
      _resolveLocalFile();
    }
  }

  Future<void> _resolveLocalFile() async {
    final mediaInfo = widget.message.mediaInfo;
    final explicitLocalPath = mediaInfo?['localPath'] as String?;

    if (explicitLocalPath != null && explicitLocalPath.isNotEmpty) {
      final file = File(explicitLocalPath);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _localFilePath = explicitLocalPath;
          });
        }
        return;
      }
    }

    final fileName = mediaInfo?['fileName'] as String? ?? '';
    if (fileName.isNotEmpty) {
      final service = getIt<MediaStorageService>();
      final found = await service.findLocalFile(fileName, widget.message.type);
      if (mounted && found != null) {
        setState(() {
          _localFilePath = found;
        });
        return;
      }
    }

    // Auto-save Base64 data directly to internal-media if received
    if (widget.message.content.startsWith('data:') ||
        (widget.message.content.length > 200 && !widget.message.content.startsWith('http'))) {
      try {
        final service = getIt<MediaStorageService>();
        final dir = await service.getMediaDir(widget.message.type);
        final safeName = fileName.isNotEmpty ? fileName : '${widget.message.type}_${widget.message.messageId}';
        final targetFile = File('${dir.path}/$safeName');
        if (!await targetFile.exists()) {
          var b64 = widget.message.content;
          if (b64.contains(',')) b64 = b64.split(',').last;
          final bytes = base64Decode(b64);
          await targetFile.writeAsBytes(bytes);
        }
        if (mounted) {
          setState(() {
            _localFilePath = targetFile.path;
          });
          return;
        }
      } catch (_) {}
    }
  }

  void _triggerDownload() {
    final mediaInfo = widget.message.mediaInfo;
    final storagePath = mediaInfo?['storagePath'] as String? ?? '';
    final fileName = mediaInfo?['fileName'] as String? ?? 'media_file';

    setState(() => _isDownloading = true);

    context.read<ChatRoomBloc>().add(
          DownloadAndPurgeMediaEvent(
            chatId: widget.message.chatId,
            messageId: widget.message.messageId,
            storagePath: storagePath,
            downloadUrl: widget.message.content,
            fileName: fileName,
            type: widget.message.type,
          ),
        );
  }

  void _openFullScreenImage(ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image(image: imageProvider),
              ),
            ),
            PositionAppBar(ctx: ctx),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.type == 'image') {
      return _buildImageView(context);
    } else if (widget.message.type == 'file') {
      return _buildFileView(context);
    } else if (widget.message.type == 'audio' || widget.message.type == 'voice') {
      return _buildAudioView(context);
    }
    return const SizedBox.shrink();
  }

  Widget _buildImageView(BuildContext context) {
    final isPurged = widget.message.mediaInfo?['isPurgedFromStorage'] == true;
    final caption = widget.message.mediaInfo?['caption'] as String?;

    Widget imageContent;

    if (_localFilePath != null) {
      // 1. Rendered directly from local internal-media storage (Instant & Offline)
      final localImage = FileImage(File(_localFilePath!));
      imageContent = GestureDetector(
        onTap: () => _openFullScreenImage(localImage),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image(
            image: localImage,
            fit: BoxFit.cover,
            width: 240,
            height: 180,
            errorBuilder: (_, __, ___) => _buildFallbackBox(isPurged),
          ),
        ),
      );
    } else if (isPurged) {
      // 2. File was purged from server and not cached locally
      imageContent = _buildPurgedPlaceholder();
    } else if (widget.message.content.startsWith('data:image') ||
        (widget.message.content.length > 200 && !widget.message.content.startsWith('http'))) {
      // Direct Base64 render
      try {
        var b64 = widget.message.content;
        if (b64.contains(',')) b64 = b64.split(',').last;
        final bytes = base64Decode(b64);
        final memImage = MemoryImage(bytes);
        imageContent = GestureDetector(
          onTap: () => _openFullScreenImage(memImage),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: 240,
              height: 180,
              errorBuilder: (_, __, ___) => _buildFallbackBox(isPurged),
            ),
          ),
        );
      } catch (_) {
        imageContent = _buildFallbackBox(isPurged);
      }
    } else if (widget.message.content.isNotEmpty) {
      // 3. File in transit on server
      imageContent = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: widget.message.content,
          fit: BoxFit.cover,
          width: 240,
          height: 180,
          placeholder: (_, __) => Container(
            width: 240,
            height: 180,
            color: AppColors.surfaceLight,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => _buildFallbackBox(isPurged),
        ),
      );
    } else {
      imageContent = _buildFallbackBox(isPurged);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        imageContent,
        if (caption != null && caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              caption,
              style: AppTextStyles.bodyMedium.copyWith(
                color: widget.isMe ? AppColors.bubbleSentText : AppColors.bubbleReceivedText,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFileView(BuildContext context) {
    final fileName = widget.message.mediaInfo?['fileName'] as String? ?? 'Document';
    final fileSize = widget.message.mediaInfo?['fileSize'] as int?;
    final isPurged = widget.message.mediaInfo?['isPurgedFromStorage'] == true;
    final formattedSize = fileSize != null ? MediaStorageService.formatBytes(fileSize) : '';

    return InkWell(
      onTap: () {
        if (_localFilePath != null) {
          launchUrl(Uri.file(_localFilePath!), mode: LaunchMode.externalApplication);
        } else if (!isPurged && widget.message.content.isNotEmpty) {
          _triggerDownload();
        } else if (widget.message.content.isNotEmpty) {
          launchUrl(Uri.parse(widget.message.content), mode: LaunchMode.externalApplication);
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
                  Row(
                    children: [
                      if (formattedSize.isNotEmpty)
                        Text(
                          formattedSize,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                        ),
                      if (_localFilePath != null) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                        const SizedBox(width: 2),
                        Text(
                          'Tersimpan',
                          style: AppTextStyles.caption.copyWith(color: AppColors.success, fontSize: 10),
                        ),
                      ] else if (isPurged) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• Kedaluwarsa di server',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (_isDownloading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_localFilePath == null && !isPurged)
              IconButton(
                icon: const Icon(Icons.download_rounded, color: AppColors.primary, size: 22),
                onPressed: _triggerDownload,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioView(BuildContext context) {
    final fileName = widget.message.mediaInfo?['fileName'] as String? ?? 'Audio message';
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
              if (_localFilePath != null) {
                launchUrl(Uri.file(_localFilePath!), mode: LaunchMode.externalApplication);
              } else if (widget.message.content.isNotEmpty) {
                launchUrl(Uri.parse(widget.message.content), mode: LaunchMode.externalApplication);
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
                Text(
                  _localFilePath != null ? 'Tersimpan di internal' : 'Audio file',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurgedPlaceholder() {
    return Container(
      width: 240,
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 36),
          SizedBox(height: 6),
          Text(
            'Media telah terhapus dari server',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBox(bool isPurged) {
    if (isPurged) return _buildPurgedPlaceholder();
    return Container(
      width: 240,
      height: 180,
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
      ),
    );
  }
}

class PositionAppBar extends StatelessWidget {
  final BuildContext ctx;
  const PositionAppBar({super.key, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 16,
      child: CircleAvatar(
        backgroundColor: Colors.black54,
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
    );
  }
}
