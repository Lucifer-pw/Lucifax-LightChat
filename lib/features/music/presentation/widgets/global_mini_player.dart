import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../bloc/music_player_cubit.dart';
import '../bloc/music_player_state.dart';

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicPlayerCubit, MusicPlayerState>(
      builder: (context, state) {
        if (!state.hasTrack) return const SizedBox.shrink();

        final track = state.currentTrack!;
        final progress = state.duration.inMilliseconds > 0
            ? (state.position.inMilliseconds / state.duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return GestureDetector(
          onTap: () {
            context.push('/music-player');
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar line at top
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 2.5,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Cover Art
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 42,
                            height: 42,
                            color: AppColors.card,
                            child: track.coverUrl != null && track.coverUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: track.coverUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Icon(
                                      Icons.music_note_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.music_note_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                  )
                                : const Icon(
                                    Icons.music_note_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Track Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                track.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                track.artist,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Play/Pause Button
                        IconButton(
                          icon: Icon(
                            state.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: AppColors.primary,
                            size: 36,
                          ),
                          onPressed: () {
                            context.read<MusicPlayerCubit>().togglePlayPause();
                          },
                        ),
                        // Close Button
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                          onPressed: () {
                            context.read<MusicPlayerCubit>().stop();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
