import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';

enum MediaPickerAction {
  camera,
  gallery,
  document,
  audio,
}

class MediaPickerResult {
  final String path;
  final String name;
  final String type; // "image" | "video" | "file" | "audio"
  final int? size;

  MediaPickerResult({
    required this.path,
    required this.name,
    required this.type,
    this.size,
  });
}

class MediaPickerSheet extends StatelessWidget {
  const MediaPickerSheet({super.key});

  static Future<MediaPickerResult?> show(BuildContext context) {
    return showModalBottomSheet<MediaPickerResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const MediaPickerSheet(),
    );
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo != null && context.mounted) {
      Navigator.pop(
        context,
        MediaPickerResult(
          path: photo.path,
          name: photo.name,
          type: 'image',
        ),
      );
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (photo != null && context.mounted) {
      Navigator.pop(
        context,
        MediaPickerResult(
          path: photo.path,
          name: photo.name,
          type: 'image',
        ),
      );
    }
  }

  Future<void> _pickDocument(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty && result.files.first.path != null && context.mounted) {
      final file = result.files.first;
      Navigator.pop(
        context,
        MediaPickerResult(
          path: file.path!,
          name: file.name,
          type: 'file',
          size: file.size,
        ),
      );
    }
  }

  Future<void> _pickAudio(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty && result.files.first.path != null && context.mounted) {
      final file = result.files.first;
      Navigator.pop(
        context,
        MediaPickerResult(
          path: file.path!,
          name: file.name,
          type: 'audio',
          size: file.size,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSizes.p16),
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p24, horizontal: AppSizes.p16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.r24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(
                context,
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: const Color(0xFFE91E63),
                onTap: () => _pickFromCamera(context),
              ),
              _buildOption(
                context,
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: const Color(0xFF9C27B0),
                onTap: () => _pickFromGallery(context),
              ),
              _buildOption(
                context,
                icon: Icons.insert_drive_file_rounded,
                label: 'Document',
                color: const Color(0xFF5C6BC0),
                onTap: () => _pickDocument(context),
              ),
              _buildOption(
                context,
                icon: Icons.headphones_rounded,
                label: 'Audio',
                color: const Color(0xFFFF9800),
                onTap: () => _pickAudio(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
