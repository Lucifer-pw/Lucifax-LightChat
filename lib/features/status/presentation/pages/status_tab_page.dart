import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/status_bloc.dart';
import '../bloc/status_state.dart';
import '../widgets/segmented_status_circle.dart';
import '../widgets/status_item_tile.dart';

class StatusTabPage extends StatefulWidget {
  const StatusTabPage({super.key});

  @override
  State<StatusTabPage> createState() => _StatusTabPageState();
}

class _StatusTabPageState extends State<StatusTabPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null && mounted) {
        context.push('/create-media-status', extra: File(pickedFile.path));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthenticatedState ? authState.user.uid : '';
    final currentUserName = authState is AuthenticatedState ? authState.user.displayName : 'You';
    final currentUserPhoto = authState is AuthenticatedState ? authState.user.photoUrl : null;

    return BlocBuilder<StatusBloc, StatusState>(
      builder: (context, state) {
        if (state is StatusLoading) {
          return const LoadingIndicator(message: 'Loading statuses...');
        }

        final myStatus = state is StatusLoaded ? state.myStatus : null;
        final recentStatuses = state is StatusLoaded ? state.recentStatuses : [];
        final viewedStatuses = state is StatusLoaded ? state.viewedStatuses : [];

        final hasMyStatus = myStatus != null && myStatus.activeItems.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
            children: [
              // My Status Header
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: 4),
                leading: Stack(
                  children: [
                    if (hasMyStatus)
                      SegmentedStatusCircle(
                        totalCount: myStatus.activeItems.length,
                        unviewedCount: 0,
                        child: CustomAvatar(
                          imageUrl: currentUserPhoto,
                          name: currentUserName,
                          radius: 26,
                        ),
                      )
                    else
                      CustomAvatar(
                        imageUrl: currentUserPhoto,
                        name: currentUserName,
                        radius: 26,
                      ),
                    if (!hasMyStatus)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  'My status',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  hasMyStatus
                      ? '${timeago.format(myStatus.latestItem!.createdAt, locale: 'en_short')} ago'
                      : 'Tap to add status update',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                trailing: hasMyStatus
                    ? IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                        onPressed: () {
                          context.push('/status-viewer', extra: myStatus);
                        },
                      )
                    : null,
                onTap: () {
                  if (hasMyStatus) {
                    context.push('/status-viewer', extra: myStatus);
                  } else {
                    _pickMedia(ImageSource.gallery);
                  }
                },
              ),

              // Recent Updates Section
              if (recentStatuses.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'RECENT UPDATES',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ...recentStatuses.map(
                  (group) => StatusItemTile(
                    statusGroup: group,
                    currentUserId: currentUserId,
                    onTap: () {
                      context.push('/status-viewer', extra: group);
                    },
                  ),
                ),
              ],

              // Viewed Updates Section
              if (viewedStatuses.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'VIEWED UPDATES',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ...viewedStatuses.map(
                  (group) => StatusItemTile(
                    statusGroup: group,
                    currentUserId: currentUserId,
                    onTap: () {
                      context.push('/status-viewer', extra: group);
                    },
                  ),
                ),
              ],

              // Empty state
              if (!hasMyStatus && recentStatuses.isEmpty && viewedStatuses.isEmpty) ...[
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.donut_large_rounded, size: 64, color: AppColors.textMuted),
                      AppSizes.vSpace16,
                      Text(
                        'No status updates',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                      AppSizes.vSpace8,
                      Text(
                        'Tap the buttons below to share what\'s on your mind',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small Text status FAB
              FloatingActionButton.small(
                heroTag: 'text_status_fab',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                elevation: 3,
                onPressed: () {
                  context.push('/create-text-status');
                },
                child: const Icon(Icons.edit_rounded, size: 20),
              ),
              const SizedBox(height: 12),
              // Camera FAB
              FloatingActionButton(
                heroTag: 'camera_status_fab',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                onPressed: () {
                  _pickMedia(ImageSource.camera);
                },
                child: const Icon(Icons.camera_alt_rounded),
              ),
            ],
          ),
        );
      },
    );
  }
}
