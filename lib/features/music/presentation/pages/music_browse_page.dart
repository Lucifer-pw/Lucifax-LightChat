import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/music_track.dart';
import '../../domain/usecases/delete_music_track.dart';
import '../../domain/usecases/get_music_tracks.dart';
import '../../domain/usecases/upload_music_track.dart';
import '../bloc/music_player_cubit.dart';
import '../bloc/music_player_state.dart';
import '../widgets/global_mini_player.dart';
import '../widgets/track_tile.dart';

class MusicBrowsePage extends StatefulWidget {
  const MusicBrowsePage({super.key});

  @override
  State<MusicBrowsePage> createState() => _MusicBrowsePageState();
}

class _MusicBrowsePageState extends State<MusicBrowsePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _uploadSong() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
    );

    if (result != null && result.files.single.path != null && mounted) {
      final audioFile = File(result.files.single.path!);
      final defaultTitle = result.files.single.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

      final titleController = TextEditingController(text: defaultTitle);
      final artistController = TextEditingController(text: 'Unknown Artist');

      final shouldUpload = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Upload Music Track'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Track Title'),
              ),
              AppSizes.vSpace12,
              TextField(
                controller: artistController,
                decoration: const InputDecoration(labelText: 'Artist / Performer'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Upload', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldUpload == true && mounted) {
        final authState = context.read<AuthBloc>().state;
        final userId = authState is AuthenticatedState ? authState.user.uid : '';

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading track in background...'), backgroundColor: AppColors.primary),
        );

        final uploadUseCase = getIt<UploadMusicTrack>();
        final uploadResult = await uploadUseCase(
          audioFile: audioFile,
          title: titleController.text.trim().isNotEmpty ? titleController.text.trim() : defaultTitle,
          artist: artistController.text.trim().isNotEmpty ? artistController.text.trim() : 'Unknown Artist',
          uploadedBy: userId,
        );

        if (mounted) {
          uploadResult.fold(
            (failure) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
            ),
            (_) => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Track uploaded successfully! 🎵'), backgroundColor: AppColors.success),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final getMusicTracks = getIt<GetMusicTracks>();
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthenticatedState ? authState.user.uid : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Music & Audio Lounge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: 'Upload Track',
            onPressed: _uploadSong,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search songs or artists...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Track List
          Expanded(
            child: StreamBuilder<List<MusicTrack>>(
              stream: getMusicTracks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator(message: 'Loading music library...');
                }

                final tracks = snapshot.data ?? [];
                final filtered = tracks.where((t) {
                  return t.title.toLowerCase().contains(_searchQuery) ||
                      t.artist.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.music_off_rounded, size: 64, color: AppColors.textMuted),
                        AppSizes.vSpace16,
                        Text(
                          _searchQuery.isEmpty ? 'No music tracks found' : 'No matching songs found',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        AppSizes.vSpace8,
                        Text('Tap the upload button above to add tracks!', style: AppTextStyles.caption),
                      ],
                    ),
                  );
                }

                return BlocBuilder<MusicPlayerCubit, MusicPlayerState>(
                  builder: (context, playerState) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: AppColors.divider,
                        indent: 80,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final track = filtered[index];
                        final isPlaying = playerState.currentTrack?.id == track.id;

                        return TrackTile(
                          track: track,
                          isPlaying: isPlaying,
                          onTap: () {
                            context.read<MusicPlayerCubit>().playTrack(track);
                          },
                          onDelete: track.uploadedBy == currentUserId
                              ? () async {
                                  final deleteTrack = getIt<DeleteMusicTrack>();
                                  await deleteTrack(track.id);
                                }
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Mini Player at bottom
          const GlobalMiniPlayer(),
        ],
      ),
    );
  }
}
