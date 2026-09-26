import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/call_entity.dart';
import '../../domain/usecases/get_call_history.dart';

class CallsTabPage extends StatelessWidget {
  const CallsTabPage({super.key});

  String _formatCallDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final callDate = DateTime(date.year, date.month, date.day);

    final timeStr = DateFormat('HH:mm').format(date);

    if (callDate == today) {
      return 'Today, $timeStr';
    } else if (callDate == yesterday) {
      return 'Yesterday, $timeStr';
    } else {
      return '${DateFormat('d MMM').format(date)}, $timeStr';
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    final minStr = mins.toString().padLeft(2, '0');
    final secStr = remainingSecs.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  void _startCallBack(BuildContext context, CallEntity call, String currentUserId) {
    final otherUserId = call.getOtherUserId(currentUserId);
    if (otherUserId.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) return;

    final newCall = CallEntity(
      callId: const Uuid().v4(),
      callerId: currentUserId,
      callerName: authState.user.displayName.isNotEmpty
          ? authState.user.displayName
          : 'LightChat User',
      callerPhoto: authState.user.photoUrl,
      receiverId: otherUserId,
      receiverName: call.getOtherUserName(currentUserId),
      receiverPhoto: call.getOtherUserPhoto(currentUserId),
      type: call.type,
      status: 'calling',
      createdAt: DateTime.now(),
    );

    appRouter.push('/call', extra: {
      'call': newCall,
      'isCaller': true,
      'currentUserId': currentUserId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthenticatedState ? authState.user.uid : '';

    if (currentUserId.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final getCallHistory = getIt<GetCallHistory>();

    return StreamBuilder<List<CallEntity>>(
      stream: getCallHistory(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final calls = snapshot.data ?? [];

        if (calls.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_outlined,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No call logs yet',
                    style: AppTextStyles.heading3.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stay in touch with your friends and family by making voice and video calls.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: calls.length,
          separatorBuilder: (context, index) => const Divider(
            color: AppColors.divider,
            height: 1,
            indent: 72,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final call = calls[index];
            final isCaller = call.callerId == currentUserId;
            final isConnected = call.status == 'connected' || call.duration > 0;
            final isMissed = !isCaller && (call.status == 'missed' || call.status == 'rejected' || call.status == 'busy');
            final otherUserId = call.getOtherUserId(currentUserId);

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirebaseConstants.usersCollection)
                  .doc(otherUserId)
                  .snapshots(),
              builder: (context, userSnap) {
                String displayName = call.getOtherUserName(currentUserId);
                String? photoUrl = call.getOtherUserPhoto(currentUserId);
                String phoneNumber = '';
                String about = 'Available';

                if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                  final data = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final liveName = data['displayName'] as String?;
                  if (liveName != null && liveName.trim().isNotEmpty) {
                    displayName = liveName;
                  }
                  final livePhoto = data['photoUrl'] as String?;
                  if (livePhoto != null && livePhoto.isNotEmpty) {
                    photoUrl = livePhoto;
                  }
                  phoneNumber = data['phoneNumber'] ?? '';
                  about = data['about'] ?? data['bio'] ?? 'Available';
                }

                // Call direction icon & color
                IconData directionIcon;
                Color iconColor;

                if (isCaller) {
                  directionIcon = Icons.call_made_rounded;
                  iconColor = AppColors.primary;
                } else if (isMissed) {
                  directionIcon = Icons.call_missed_rounded;
                  iconColor = AppColors.error;
                } else {
                  directionIcon = Icons.call_received_rounded;
                  iconColor = isConnected ? AppColors.onlineIndicator : AppColors.error;
                }

                final durationText = call.duration > 0
                    ? ' • ${_formatDuration(call.duration)}'
                    : (isMissed ? ' • (Missed)' : '');

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CustomAvatar(
                    imageUrl: photoUrl,
                    name: displayName,
                    radius: 24,
                    onTap: () {
                      if (otherUserId.isNotEmpty) {
                        appRouter.push('/contact-profile', extra: {
                          'userId': otherUserId,
                          'displayName': displayName,
                          'photoUrl': photoUrl,
                          'phoneNumber': phoneNumber,
                          'about': about,
                        });
                      }
                    },
                  ),
                  title: Text(
                    displayName,
                    style: AppTextStyles.chatTitle.copyWith(
                      color: isMissed ? AppColors.error : Colors.white,
                      fontWeight: isMissed ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Row(
                    children: [
                      Icon(directionIcon, size: 16, color: iconColor),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatCallDate(call.createdAt)}$durationText',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      call.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    onPressed: () => _startCallBack(context, call, currentUserId),
                  ),
                  onTap: () => _startCallBack(context, call, currentUserId),
                );
              },
            );
          },
        );
      },
    );
  }
}
