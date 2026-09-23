import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/music_track.dart';

class TrackTile extends StatelessWidget {
  final MusicTrack track;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const TrackTile({
    super.key,
    required this.track,
    this.isPlaying = false,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 50,
          height: 50,
          color: AppColors.surface,
          child: track.coverUrl != null && track.coverUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: track.coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.textMuted,
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.textMuted,
                  ),
                )
              : const Icon(
                  Icons.music_note_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
        ),
      ),
      title: Text(
        track.title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          color: isPlaying ? AppColors.primary : AppColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPlaying)
            const Icon(Icons.equalizer_rounded, color: AppColors.primary, size: 24),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
              onPressed: onDelete,
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
