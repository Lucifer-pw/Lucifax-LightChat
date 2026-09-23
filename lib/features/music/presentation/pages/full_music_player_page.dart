import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../bloc/music_player_cubit.dart';
import '../bloc/music_player_state.dart';

class FullMusicPlayerPage extends StatelessWidget {
  const FullMusicPlayerPage({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicPlayerCubit, MusicPlayerState>(
      builder: (context, state) {
        if (!state.hasTrack) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: Colors.transparent),
            body: const Center(child: Text('No track is currently playing')),
          );
        }

        final track = state.currentTrack!;
        final totalDuration = state.duration;
        final currentPosition = state.position;
        final maxSeconds = totalDuration.inSeconds > 0 ? totalDuration.inSeconds.toDouble() : 1.0;
        final currentSeconds = currentPosition.inSeconds.toDouble().clamp(0.0, maxSeconds);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Now Playing'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),
                // Album Art Card
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.r24),
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.r24),
                      child: track.coverUrl != null && track.coverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: track.coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Icon(
                                Icons.music_note_rounded,
                                size: 80,
                                color: AppColors.primary,
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.music_note_rounded,
                                size: 80,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.music_note_rounded,
                              size: 100,
                              color: AppColors.primary,
                            ),
                    ),
                  ),
                ),
                AppSizes.vSpace32,

                // Track Info
                Text(
                  track.title,
                  style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSizes.vSpace8,
                Text(
                  track.artist,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(flex: 1),

                // Seek Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: currentSeconds,
                    min: 0.0,
                    max: maxSeconds,
                    onChanged: (val) {
                      context.read<MusicPlayerCubit>().seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),

                // Timestamps
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(currentPosition),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        _formatDuration(totalDuration),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                AppSizes.vSpace24,

                // Controls Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.repeat_rounded,
                        color: state.isLooping ? AppColors.primary : AppColors.textMuted,
                        size: 26,
                      ),
                      onPressed: () {
                        context.read<MusicPlayerCubit>().toggleLoop();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded, size: 32),
                      onPressed: () {
                        final newPos = currentPosition - const Duration(seconds: 10);
                        context.read<MusicPlayerCubit>().seek(
                              newPos < Duration.zero ? Duration.zero : newPos,
                            );
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        context.read<MusicPlayerCubit>().togglePlayPause();
                      },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          state.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded, size: 32),
                      onPressed: () {
                        final newPos = currentPosition + const Duration(seconds: 10);
                        context.read<MusicPlayerCubit>().seek(newPos);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop_rounded, color: AppColors.textMuted, size: 28),
                      onPressed: () {
                        context.read<MusicPlayerCubit>().stop();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        );
      },
    );
  }
}
